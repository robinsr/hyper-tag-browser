// created on 10/26/26 by robinsr

import Foundation
import GRDB
import Nimble
import System
import Testing

@testable import HyperTagBrowser

@Suite("SQLiteMetricsSink")
struct SQLiteMetricsSinkTest {

  let sink: SQLiteMetricsSink
  let session = MetricsSession(
    id: "session-1",
    startedAt: Date(timeIntervalSince1970: 1_800_000_000),
    appVersion: "1.0",
    buildNumber: "100",
    osVersion: "macOS 15",
    mainDbName: "main.sqlite"
  )

  init() throws {
    sink = try SQLiteMetricsSink(queue: DatabaseQueue())
    try sink.begin(session: session)
  }

  func count(_ table: String) throws -> Int {
    try sink.database.read { db in
      try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
    }
  }

  func span(_ name: String, at date: Date) -> SpanRecord {
    SpanRecord(
      id: UUID().uuidString, traceId: "t", parentId: nil, name: name, startedAt: date,
      durationMs: 1.5, outcome: .ok, tags: ["files": "3"])
  }

  func timing(_ name: String, ms: Double) -> TimingAggregate {
    var aggregate = TimingAggregate(key: TimingKey(name: name, tags: ["stmt": "abc"]))
    aggregate.add(ms)
    return aggregate
  }

  @Test("begin and end write the session row")
  func test_session() throws {
    let ended = session.startedAt.addingTimeInterval(60)
    try sink.end(sessionId: session.id, at: ended)

    let row = try #require(
      try sink.database.read { db in
        try Row.fetchOne(db, sql: "SELECT * FROM sessions WHERE id = ?", arguments: [session.id])
      })
    expect(row["build_number"] as String?).to(equal("100"))
    expect(row["ended_at"] as Date?).to(equal(ended))
  }

  @Test("spans are written with JSON tags")
  func test_spans() throws {
    try sink.write(spans: [span("index.list", at: session.startedAt)], sessionId: session.id)

    let tags = try sink.database.read { db in
      try String.fetchOne(db, sql: "SELECT tags FROM spans WHERE name = 'index.list'")
    }
    expect(tags).to(equal(#"{"files":"3"}"#))
  }

  @Test("timings reference the snapshot and store 16 buckets")
  func test_snapshot_and_timings() throws {
    let snapshot = DBSnapshot(
      takenAt: session.startedAt, fileBytes: 4096, walBytes: 0,
      rowCounts: ["app_content_indices": 10])
    let snapshotId = try sink.write(snapshot: snapshot, sessionId: session.id)

    try sink.write(
      timings: [timing("sql", ms: 2)], sessionId: session.id, snapshotId: snapshotId,
      windowStart: session.startedAt, windowSecs: 60)

    let row = try #require(
      try sink.database.read { db in
        try Row.fetchOne(db, sql: "SELECT * FROM timings")
      })
    expect(row["snapshot_id"] as Int64?).to(equal(snapshotId))
    expect(row["count"] as Int?).to(equal(1))
    expect(row["tags"] as String?).to(equal(#"{"stmt":"abc"}"#))
    expect(row["buckets"] as String?).to(equal("[0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0]"))

    let counts = try sink.database.read { db in
      try String.fetchOne(db, sql: "SELECT row_counts FROM db_snapshots")
    }
    expect(counts).to(equal(#"{"app_content_indices":10}"#))
  }

  @Test("statements are inserted once")
  func test_statements_insert_or_ignore() throws {
    let info = SQLStatementInfo(hash: "0f3f1b3b5890c008", kind: "select", normalizedSQL: "SELECT 1")
    try sink.write(statements: [info], firstSeen: session.startedAt)
    try sink.write(statements: [info], firstSeen: session.startedAt)
    expect(try count("sql_statements")).to(equal(1))
  }

  @Test("prune deletes old spans and timings only")
  func test_prune() throws {
    let old = session.startedAt.addingTimeInterval(-100 * 86_400)
    let recent = session.startedAt
    try sink.write(
      spans: [span("old", at: old), span("recent", at: recent)], sessionId: session.id)
    try sink.write(
      timings: [timing("a", ms: 1)], sessionId: session.id, snapshotId: nil,
      windowStart: old, windowSecs: 60)
    try sink.write(
      timings: [timing("b", ms: 1)], sessionId: session.id, snapshotId: nil,
      windowStart: recent, windowSecs: 60)

    try sink.prune(olderThan: session.startedAt.addingTimeInterval(-90 * 86_400))

    expect(try count("spans")).to(equal(1))
    expect(try count("timings")).to(equal(1))
    expect(try count("sessions")).to(equal(1))
  }

  @Test("openOrRecover sets aside a corrupt file and creates a fresh one")
  func test_recover_corrupt_file() throws {
    let dir = SystemLocation.tmpDir.appending("metrics-sink-\(UUID().uuidString)")
    try FileManager.default.createDirectory(atPath: dir.string, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: dir.string) }

    let path = dir.appending("metrics.sqlite")
    try Data(repeating: 0x42, count: 4096).write(to: URL(filePath: path.string))

    let recovered = SQLiteMetricsSink.openOrRecover(
      at: path, logger: CustomLogger("SQLiteMetricsSinkTest"))

    expect(recovered).notTo(beNil())
    let names = try FileManager.default.contentsOfDirectory(atPath: dir.string)
    expect(names.contains { $0.hasPrefix("metrics.sqlite.bad-") }).to(beTrue())
  }

  @Test("DBSnapshot.take counts base tables and skips views")
  func test_take_snapshot() async throws {
    let (_, queue) = try await TestSupportDB.setupDB()

    let snapshot = try DBSnapshot.take(reader: queue, path: nil)

    expect(snapshot.rowCounts[IndexRecord.databaseTableName])
      .to(equal(IndexRecordFixture.records.count))
    expect(Set(snapshot.rowCounts.keys).isDisjoint(with: SchemaConfiguration.viewNames))
      .to(beTrue())
    expect(snapshot.fileBytes).to(equal(0))
  }
}
