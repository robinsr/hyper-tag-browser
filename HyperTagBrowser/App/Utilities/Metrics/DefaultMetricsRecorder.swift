// created on 10/26/26 by robinsr

import Foundation
import OSLog
import Synchronization
import System

typealias DBSnapshotProvider = @Sendable () throws -> DBSnapshot?


/// Remembers which statement hashes have been seen and holds new ones until the next flush.
final class StatementRegistry: Sendable {
  private struct State {
    var seen: Set<String> = []
    var pending: [SQLStatementInfo] = []
  }

  private let state = Mutex(State())

  func register(_ info: SQLStatementInfo) {
    state.withLock { state in
      if state.seen.insert(info.hash).inserted {
        state.pending.append(info)
      }
    }
  }

  func drain() -> [SQLStatementInfo] {
    state.withLock { state in
      defer { state.pending.removeAll() }
      return state.pending
    }
  }
}


final class DefaultMetricsRecorder: MetricsRecorder {
  static let defaultFlushInterval: Duration = .seconds(60)
  static let snapshotInterval: TimeInterval = 300
  static let retention: TimeInterval = 90 * 24 * 60 * 60

  let session: MetricsSession

  private let sink: any MetricsSink
  private let snapshotProvider: DBSnapshotProvider
  private let flushInterval: Duration?
  private let logFlushes: Bool
  private let logger = CustomLogger("DefaultMetricsRecorder", level: .info)

  private let aggregator = TimingAggregator()
  private let spans: SpanBuffer
  private let statements = StatementRegistry()
  private let emitter: SpanEmitter
  private let queue = DispatchQueue(label: "metrics.flush", qos: .utility)
  private let flushTask = Mutex<Task<Void, Never>?>(nil)
  private let state: Mutex<FlushState>

  private struct FlushState {
    var windowStart: Date
    var lastSnapshotAt: Date?
    var lastSnapshotId: Int64?
    var loggedFailures: Set<String> = []
  }

  /// - Parameter flushInterval: nil disables periodic flushing (tests flush manually).
  init(
    session: MetricsSession,
    sink: any MetricsSink,
    signposter: OSSignposter,
    snapshotProvider: @escaping DBSnapshotProvider,
    flushInterval: Duration? = DefaultMetricsRecorder.defaultFlushInterval,
    logFlushes: Bool = false
  ) {
    self.session = session
    self.sink = sink
    self.snapshotProvider = snapshotProvider
    self.flushInterval = flushInterval
    self.logFlushes = logFlushes
    self.state = Mutex(FlushState(windowStart: session.startedAt))

    // Built from a local: `self` can't be read until every stored property is set
    let spans = SpanBuffer()
    self.spans = spans
    self.emitter = SpanEmitter(signposter: signposter, onStop: { spans.append($0) })
  }

  /// Writes the session row, prunes old data, takes the first snapshot, and starts the
  /// periodic flush. The writes happen on the flush queue so launch isn't blocked.
  func start(now: Date = Date()) {
    queue.async { [self] in
      perform("session") { try sink.begin(session: session) }
      perform("prune") { try sink.prune(olderThan: now.addingTimeInterval(-Self.retention)) }
      takeSnapshot(at: now)
    }

    guard let interval = flushInterval else { return }

    flushTask.withLock { task in
      task = Task.detached(priority: .utility) { [weak self] in
        while !Task.isCancelled {
          try? await Task.sleep(for: interval)
          self?.flush()
        }
      }
    }
  }

  // MARK: - MetricsRecorder

  func span(_ name: StaticString, tags: MetricTags) -> MetricSpan {
    emitter.start(name, tags: tags, parent: nil)
  }

  func timing(_ name: String, ms: Double, tags: MetricTags) {
    guard ms.isFinite, ms >= 0 else { return }
    aggregator.record(name, ms: ms, tags: tags)
  }

  func register(statement: SQLStatementInfo) {
    statements.register(statement)
  }

  func flush() {
    flush(now: Date())
  }

  func shutdown(timeout: Duration) {
    flushTask.withLock { task in
      task?.cancel()
      task = nil
    }

    let done = DispatchSemaphore(value: 0)

    DispatchQueue.global(qos: .userInitiated).async { [self] in
      flush(now: Date())
      perform("session") { try sink.end(sessionId: session.id, at: Date()) }
      done.signal()
    }

    _ = done.wait(timeout: .now() + .milliseconds(Int(timeout.milliseconds)))
  }

  // MARK: - Flushing

  func flush(now: Date) {
    queue.sync {
      let timings = aggregator.drain()
      let spanRecords = spans.drain()
      let newStatements = statements.drain()

      perform("statements") { try sink.write(statements: newStatements, firstSeen: now) }
      perform("spans") { try sink.write(spans: spanRecords, sessionId: session.id) }

      guard !timings.isEmpty || !spanRecords.isEmpty else {
        state.withLock { $0.windowStart = now }
        return
      }

      if snapshotDue(at: now) {
        takeSnapshot(at: now)
      }

      let (windowStart, snapshotId) = state.withLock { state in
        defer { state.windowStart = now }
        return (state.windowStart, state.lastSnapshotId)
      }

      let windowSecs = max(1, Int(now.timeIntervalSince(windowStart).rounded()))

      perform("timings") {
        try sink.write(
          timings: timings, sessionId: session.id, snapshotId: snapshotId,
          windowStart: windowStart, windowSecs: windowSecs)
      }

      if logFlushes {
        logger.emit(.info, "Metrics flush: \(timings.count) timings, \(spanRecords.count) spans")
      }
    }
  }

  private func snapshotDue(at now: Date) -> Bool {
    state.withLock { state in
      guard let last = state.lastSnapshotAt else { return true }
      return now.timeIntervalSince(last) >= Self.snapshotInterval
    }
  }

  private func takeSnapshot(at date: Date) {
    guard let snapshot = perform("snapshot", { try snapshotProvider() }) ?? nil,
      let snapshotId = perform(
        "snapshot", { try sink.write(snapshot: snapshot, sessionId: session.id) })
    else { return }

    state.withLock { state in
      state.lastSnapshotAt = date
      state.lastSnapshotId = snapshotId
    }
  }

  /// Runs a sink call. Failures drop the batch and are logged once per phase per session.
  @discardableResult
  private func perform<T>(_ phase: String, _ body: () throws -> T) -> T? {
    do {
      return try body()
    } catch {
      let isFirst = state.withLock { $0.loggedFailures.insert(phase).inserted }

      if isFirst {
        logger.emit(.error, "Metrics \(phase) write failed; dropping batch: \(error)")
      }

      return nil
    }
  }
}


extension DefaultMetricsRecorder {
  /// The app's recorder: `metrics.sqlite` in Application Support, signposts in Points of
  /// Interest, snapshots of the active index database. Falls back to a no-op recorder if the
  /// metrics file can't be opened.
  static func makeForApp() -> any MetricsRecorder {
    let logger = CustomLogger("Metrics", level: .info)
    let directory = AppLocation.appSupport

    try? FileManager.default.createDirectory(
      atPath: directory.string, withIntermediateDirectories: true)

    guard
      let sink = SQLiteMetricsSink.openOrRecover(
        at: directory.appending("metrics.sqlite"), logger: logger)
    else {
      return NoopMetricsRecorder()
    }

    let info = Bundle.main.infoDictionary ?? [:]
    let databasePath = IndexerContainer.shared.databasePath()

    let session = MetricsSession(
      id: UUID().uuidString,
      startedAt: Date(),
      appVersion: info["CFBundleShortVersionString"] as? String ?? "unknown",
      buildNumber: info["CFBundleVersion"] as? String ?? "unknown",
      osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
      mainDbName: databasePath.baseName
    )

    let recorder = DefaultMetricsRecorder(
      session: session,
      sink: sink,
      signposter: OSSignposter(
        subsystem: Bundle.main.bundleIdentifier ?? Constants.appDisplayName,
        category: .pointsOfInterest),
      snapshotProvider: {
        let indexer = IndexerContainer.shared.indexService()
        return try DBSnapshot.take(reader: indexer.dbReader, path: databasePath)
      },
      logFlushes: RunFlags().emitMetrics
    )

    recorder.start()

    return recorder
  }
}
