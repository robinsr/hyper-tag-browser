// created on 10/26/26 by robinsr

import Factory
import Foundation
import GRDB
import Nimble
import Testing

@testable import HyperTagBrowser

@Suite("SQL profiling", .serialized)
struct SQLProfilingTest {

  // MARK: - SQLNormalizer

  @Test("whitespace is collapsed and parenthesized placeholder lists merge")
  func test_normalize() {
    let sql = "SELECT *\n   FROM t\tWHERE id IN (?, ?,?) AND x = ?"
    expect(SQLNormalizer.normalize(sql)).to(equal("SELECT * FROM t WHERE id IN (?…) AND x = ?"))
    expect(SQLNormalizer.normalize("WHERE id IN (?)")).to(equal("WHERE id IN (?…)"))
  }

  @Test("kind comes from the first keyword")
  func test_kind() {
    expect(SQLNormalizer.kind(of: "SELECT 1")).to(equal("select"))
    expect(SQLNormalizer.kind(of: "WITH x AS (SELECT 1) SELECT * FROM x")).to(equal("select"))
    expect(SQLNormalizer.kind(of: "INSERT OR REPLACE INTO t VALUES (?…)")).to(equal("insert"))
    expect(SQLNormalizer.kind(of: "update t SET a = ?")).to(equal("update"))
    expect(SQLNormalizer.kind(of: "DELETE FROM t")).to(equal("delete"))
    expect(SQLNormalizer.kind(of: "BEGIN DEFERRED TRANSACTION")).to(equal("begin"))
    expect(SQLNormalizer.kind(of: "COMMIT TRANSACTION")).to(equal("commit"))
    expect(SQLNormalizer.kind(of: "PRAGMA foreign_keys")).to(equal("other"))
  }

  @Test("FNV-1a 64 matches reference vectors (key stability)")
  func test_fnv_golden() {
    expect(SQLNormalizer.fnv1a64("")).to(equal("cbf29ce484222325"))
    expect(SQLNormalizer.fnv1a64("a")).to(equal("af63dc4c8601ec8c"))
    expect(SQLNormalizer.fnv1a64("foobar")).to(equal("85944171f73967e8"))
    expect(SQLNormalizer.info(for: "SELECT * FROM t WHERE id IN (?, ?)").hash)
      .to(equal("0f3f1b3b5890c008"))
  }

  // MARK: - SQLStatementProfiler

  @Test("profiler records sql timings and registers each statement once")
  func test_profiler_records() throws {
    let recorder = RecordingMetricsRecorder()
    let profiler = SQLStatementProfiler(recorder: recorder, connection: "writer")

    var config = Configuration()
    config.prepareDatabase { db in
      db.trace(options: .profile) { profiler.handle($0) }
    }

    let queue = try DatabaseQueue(configuration: config)
    try queue.write { db in
      try db.execute(sql: "CREATE TABLE t (x INTEGER)")
      try db.execute(sql: "INSERT INTO t (x) VALUES (1), (2)")
      _ = try Row.fetchAll(db, sql: "SELECT * FROM t WHERE x IN (?, ?)", arguments: [1, 2])
      _ = try Row.fetchAll(db, sql: "SELECT * FROM t WHERE x IN (?, ?)", arguments: [1, 2])
    }

    let sqlTimings = recorder.timings.drain().filter { $0.key.name == "sql" }
    expect(sqlTimings).notTo(beEmpty())
    expect(sqlTimings.allSatisfy { $0.key.tags["conn"] == "writer" }).to(beTrue())

    let registered = recorder.statements.drain()
    let selects = registered.filter { $0.normalizedSQL == "SELECT * FROM t WHERE x IN (?…)" }
    expect(selects).to(haveCount(1))
  }

  // Note: HyperTagBrowser and HyperTagBrowserTests each statically link the Factory package
  // into their own binary, so `Container.shared` in this test and `Container.shared` inside
  // app-target code (e.g. GRDBIndexService.configure()) are different storage; a
  // `Container.shared.metricsRecorder.register` here is never observed by the app's profiler.
  // This smoke-tests that configure() wires tracing without crashing; end-to-end wiring is
  // verified against the real app in docs/metrics/instruments.md's manual check.
  @Test("GRDBIndexService.configure installs tracing without crashing")
  func test_configure_installs_profiler() throws {
    let queue = try DatabaseQueue(configuration: GRDBIndexService.configure())
    try queue.write { db in
      try db.execute(sql: "CREATE TABLE t (x INTEGER)")
      _ = try Row.fetchAll(db, sql: "SELECT * FROM t")
    }
  }
}
