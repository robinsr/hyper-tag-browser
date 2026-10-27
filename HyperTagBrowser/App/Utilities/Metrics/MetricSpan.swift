// created on 10/26/26 by robinsr

import Foundation
import OSLog
import Synchronization

enum SpanOutcome: String, Sendable {
  case ok
  case error
}


/// A completed span, as persisted.
struct SpanRecord: Equatable, Sendable {
  let id: String
  let traceId: String
  let parentId: String?
  let name: String
  let startedAt: Date
  let durationMs: Double
  let outcome: SpanOutcome
  let tags: MetricTags
}


/// Starts spans and receives their records when they stop.
///
/// `@unchecked Sendable`: `OSSignposter` is documented as thread-safe.
struct SpanEmitter: @unchecked Sendable {
  let signposter: OSSignposter
  let onStop: @Sendable (SpanRecord) -> Void

  static let silent = SpanEmitter(signposter: .disabled, onStop: { _ in })

  func start(_ name: StaticString, tags: MetricTags, parent: MetricSpan?) -> MetricSpan {
    MetricSpan(name: name, tags: tags, parent: parent, emitter: self)
  }
}


/// A named, timed interval. Shows in Instruments (Points of Interest) and is written to
/// `metrics.sqlite` as one row when stopped. Use for low-volume steps only; use timings for
/// anything that runs per file or per statement.
final class MetricSpan: Sendable {
  let id: String
  let traceId: String
  let parentId: String?
  let name: StaticString
  let startedAt: Date

  private let start: ContinuousClock.Instant
  private let emitter: SpanEmitter
  private let state: Mutex<State>

  private struct State {
    var tags: MetricTags
    var interval: OSSignpostIntervalState?
    var stopped = false
  }

  fileprivate init(name: StaticString, tags: MetricTags, parent: MetricSpan?, emitter: SpanEmitter)
  {
    let id = UUID().uuidString
    self.id = id
    self.traceId = parent?.traceId ?? id
    self.parentId = parent?.id
    self.name = name
    self.startedAt = Date()
    self.start = ContinuousClock.now
    self.emitter = emitter

    let signposter = emitter.signposter
    let interval = signposter.beginInterval(name, id: signposter.makeSignpostID())
    self.state = Mutex(State(tags: tags, interval: interval))
  }

  func tag(_ key: String, _ value: some CustomStringConvertible) {
    state.withLock { $0.tags[key] = value.description }
  }

  func child(_ name: StaticString, tags: MetricTags = [:]) -> MetricSpan {
    emitter.start(name, tags: tags, parent: self)
  }

  /// Ends the span. Calls after the first are ignored.
  func stop(outcome: SpanOutcome = .ok) {
    let durationMs = start.elapsedMs
    let name = self.name
    let signposter = emitter.signposter

    let tags: MetricTags? = state.withLock { state in
      guard !state.stopped else { return nil }
      state.stopped = true

      if let interval = state.interval {
        signposter.endInterval(name, interval)
      }

      return state.tags
    }

    guard let tags else { return }

    emitter.onStop(
      SpanRecord(
        id: id,
        traceId: traceId,
        parentId: parentId,
        name: String(describing: name),
        startedAt: startedAt,
        durationMs: durationMs,
        outcome: outcome,
        tags: tags
      ))
  }

  /// Runs `body`, then stops the span: `.ok` on return, `.error` if `body` throws.
  func measure<T>(_ body: (MetricSpan) throws -> T) rethrows -> T {
    do {
      let result = try body(self)
      stop()
      return result
    } catch {
      stop(outcome: .error)
      throw error
    }
  }
}


/// Holds stopped spans until the next flush.
final class SpanBuffer: Sendable {
  private let records = Mutex<[SpanRecord]>([])

  func append(_ record: SpanRecord) {
    records.withLock { $0.append(record) }
  }

  func drain() -> [SpanRecord] {
    records.withLock { records in
      defer { records.removeAll() }
      return records
    }
  }

  var all: [SpanRecord] {
    records.withLock { $0 }
  }
}
