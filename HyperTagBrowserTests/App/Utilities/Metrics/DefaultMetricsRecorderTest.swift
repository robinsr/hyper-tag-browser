// created on 10/26/26 by robinsr

import Foundation
import GRDB
import Nimble
import Testing

@testable import HyperTagBrowser

@Suite("DefaultMetricsRecorder")
struct DefaultMetricsRecorderTest {

  struct SinkDown: Error {}

  let t0 = Date(timeIntervalSince1970: 1_800_000_000)
  let sink: SQLiteMetricsSink

  init() throws {
    sink = try SQLiteMetricsSink(queue: DatabaseQueue())
  }

  func makeRecorder(sink: any MetricsSink, snapshots: Int = 7) -> DefaultMetricsRecorder {
    DefaultMetricsRecorder(
      session: MetricsSession(
        id: "s1", startedAt: t0, appVersion: "1", buildNumber: "1", osVersion: "x",
        mainDbName: "db"),
      sink: sink,
      signposter: .disabled,
      snapshotProvider: {
        DBSnapshot(takenAt: Date(), fileBytes: 1, walBytes: 0, rowCounts: ["t": snapshots])
      },
      flushInterval: nil
    )
  }

  func count(_ table: String) throws -> Int {
    try sink.database.read { try Int.fetchOne($0, sql: "SELECT COUNT(*) FROM \(table)") ?? 0 }
  }

  @Test("start writes the session and an initial snapshot")
  func test_start() throws {
    let recorder = makeRecorder(sink: sink)
    recorder.start(now: t0)
    recorder.flush(now: t0)

    expect(try count("sessions")).to(equal(1))
    expect(try count("db_snapshots")).to(equal(1))
  }

  @Test("flush writes timings linked to the latest snapshot")
  func test_flush_timings() throws {
    let recorder = makeRecorder(sink: sink)
    recorder.start(now: t0)
    recorder.timing("sql", ms: 3, tags: ["stmt": "abc"])
    recorder.timing("sql", ms: 5, tags: ["stmt": "abc"])
    recorder.flush(now: t0.addingTimeInterval(60))

    let row = try #require(
      try sink.database.read { db in
        try Row.fetchOne(db, sql: "SELECT * FROM timings")
      })
    expect(row["count"] as Int?).to(equal(2))
    expect(row["window_secs"] as Int?).to(equal(60))
    expect(row["snapshot_id"] as Int64?).notTo(beNil())
  }

  @Test("stopped spans are written on flush")
  func test_flush_spans() throws {
    let recorder = makeRecorder(sink: sink)
    recorder.start(now: t0)
    recorder.span("index.directory").stop()
    recorder.flush(now: t0.addingTimeInterval(1))

    expect(try count("spans")).to(equal(1))
  }

  @Test("registered statements are written once")
  func test_statements() throws {
    let recorder = makeRecorder(sink: sink)
    recorder.start(now: t0)
    let info = SQLStatementInfo(hash: "h", kind: "select", normalizedSQL: "SELECT 1")
    recorder.register(statement: info)
    recorder.register(statement: info)
    recorder.flush(now: t0)
    recorder.register(statement: info)
    recorder.flush(now: t0)

    expect(try count("sql_statements")).to(equal(1))
  }

  @Test("snapshots are retaken only after five minutes")
  func test_snapshot_interval() throws {
    let recorder = makeRecorder(sink: sink)
    recorder.start(now: t0)

    recorder.timing("a", ms: 1)
    recorder.flush(now: t0.addingTimeInterval(60))
    expect(try count("db_snapshots")).to(equal(1))

    recorder.timing("a", ms: 1)
    recorder.flush(now: t0.addingTimeInterval(301))
    expect(try count("db_snapshots")).to(equal(2))
  }

  @Test("a failing sink does not throw or crash")
  func test_failing_sink() {
    let recorder = makeRecorder(sink: FailingSink())
    recorder.start(now: t0)
    recorder.timing("a", ms: 1)
    recorder.span("index.directory").stop()
    recorder.flush(now: t0.addingTimeInterval(60))
    recorder.shutdown()
  }

  @Test("shutdown flushes and ends the session")
  func test_shutdown() throws {
    let recorder = makeRecorder(sink: sink)
    recorder.start(now: t0)
    recorder.timing("a", ms: 1)
    recorder.shutdown(timeout: .seconds(2))

    expect(try count("timings")).to(equal(1))
    let ended = try sink.database.read { db in
      try Date.fetchOne(db, sql: "SELECT ended_at FROM sessions")
    }
    expect(ended).notTo(beNil())
  }

  @Test("noop recorder spans still time but record nothing")
  func test_noop() {
    let recorder = NoopMetricsRecorder()
    let value = recorder.time("a") { 7 }
    expect(value).to(equal(7))
    recorder.span("index.directory").stop()
  }

  final class FailingSink: MetricsSink {
    func begin(session: MetricsSession) throws { throw SinkDown() }
    func end(sessionId: String, at date: Date) throws { throw SinkDown() }
    func write(spans: [SpanRecord], sessionId: String) throws { throw SinkDown() }
    func write(snapshot: DBSnapshot, sessionId: String) throws -> Int64 { throw SinkDown() }
    func write(
      timings: [TimingAggregate], sessionId: String, snapshotId: Int64?, windowStart: Date,
      windowSecs: Int
    ) throws { throw SinkDown() }
    func write(statements: [SQLStatementInfo], firstSeen: Date) throws { throw SinkDown() }
    func prune(olderThan cutoff: Date) throws { throw SinkDown() }
  }
}
