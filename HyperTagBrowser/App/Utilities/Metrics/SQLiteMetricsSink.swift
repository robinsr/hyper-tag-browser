// created on 10/26/26 by robinsr

import Foundation
import GRDB
import System

/// Writes metrics to a dedicated SQLite file, separate from the index database.
final class SQLiteMetricsSink: MetricsSink {
  let database: DatabaseQueue

  init(queue: DatabaseQueue) throws {
    self.database = queue
    try Self.migrator.migrate(queue)
  }

  convenience init(path: FilePath) throws {
    try self.init(queue: DatabaseQueue(path: path.string))
  }

  /// Opens the sink at `path`. If the file can't be opened or migrated, it is renamed to
  /// `<name>.bad-<unix time>` and a fresh file is created. Returns nil if that fails too.
  static func openOrRecover(at path: FilePath, logger: CustomLogger) -> SQLiteMetricsSink? {
    do {
      return try SQLiteMetricsSink(path: path)
    } catch {
      logger.emit(.error, "metrics.sqlite is unusable, setting it aside: \(error)")
    }

    let fileName = path.lastComponent?.string ?? "metrics.sqlite"
    let badPath = path.removingLastComponent()
      .appending("\(fileName).bad-\(Int(Date().timeIntervalSince1970))")

    do {
      try FileManager.default.moveItem(atPath: path.string, toPath: badPath.string)

      for suffix in ["-wal", "-shm"] {
        try? FileManager.default.removeItem(atPath: path.string + suffix)
      }

      return try SQLiteMetricsSink(path: path)
    } catch {
      logger.emit(.error, "metrics.sqlite recovery failed: \(error)")
      return nil
    }
  }

  private static var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1") { db in
      try db.execute(
        sql: """
          CREATE TABLE sessions (
            id            TEXT PRIMARY KEY,
            started_at    DATETIME NOT NULL,
            ended_at      DATETIME,
            app_version   TEXT NOT NULL,
            build_number  TEXT NOT NULL,
            os_version    TEXT NOT NULL,
            main_db_name  TEXT NOT NULL
          );

          CREATE TABLE spans (
            id            TEXT PRIMARY KEY,
            session_id    TEXT NOT NULL REFERENCES sessions(id),
            trace_id      TEXT NOT NULL,
            parent_id     TEXT,
            name          TEXT NOT NULL,
            started_at    DATETIME NOT NULL,
            duration_ms   DOUBLE NOT NULL,
            outcome       TEXT NOT NULL,
            tags          TEXT NOT NULL
          );
          CREATE INDEX spans_trace ON spans(trace_id);
          CREATE INDEX spans_name_time ON spans(name, started_at);

          CREATE TABLE db_snapshots (
            id            INTEGER PRIMARY KEY,
            session_id    TEXT NOT NULL REFERENCES sessions(id),
            taken_at      DATETIME NOT NULL,
            file_bytes    INTEGER NOT NULL,
            wal_bytes     INTEGER NOT NULL,
            row_counts    TEXT NOT NULL
          );

          CREATE TABLE timings (
            id            INTEGER PRIMARY KEY,
            session_id    TEXT NOT NULL REFERENCES sessions(id),
            snapshot_id   INTEGER REFERENCES db_snapshots(id),
            window_start  DATETIME NOT NULL,
            window_secs   INTEGER NOT NULL,
            name          TEXT NOT NULL,
            tags          TEXT NOT NULL,
            count         INTEGER NOT NULL,
            sum_ms        DOUBLE NOT NULL,
            min_ms        DOUBLE NOT NULL,
            max_ms        DOUBLE NOT NULL,
            buckets       TEXT NOT NULL
          );
          CREATE INDEX timings_name_time ON timings(name, window_start);

          CREATE TABLE sql_statements (
            hash           TEXT PRIMARY KEY,
            kind           TEXT NOT NULL,
            normalized_sql TEXT NOT NULL,
            first_seen     DATETIME NOT NULL
          );
          """)
    }

    return migrator
  }

  func begin(session: MetricsSession) throws {
    try database.write { db in
      try db.execute(
        sql: """
          INSERT INTO sessions
            (id, started_at, app_version, build_number, os_version, main_db_name)
          VALUES (?, ?, ?, ?, ?, ?)
          """,
        arguments: [
          session.id, session.startedAt, session.appVersion, session.buildNumber,
          session.osVersion, session.mainDbName,
        ])
    }
  }

  func end(sessionId: String, at date: Date) throws {
    try database.write { db in
      try db.execute(
        sql: "UPDATE sessions SET ended_at = ? WHERE id = ?", arguments: [date, sessionId])
    }
  }

  func write(spans: [SpanRecord], sessionId: String) throws {
    guard !spans.isEmpty else { return }

    try database.write { db in
      for span in spans {
        try db.execute(
          sql: """
            INSERT INTO spans
              (id, session_id, trace_id, parent_id, name, started_at, duration_ms, outcome, tags)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
          arguments: [
            span.id, sessionId, span.traceId, span.parentId, span.name, span.startedAt,
            span.durationMs, span.outcome.rawValue, span.tags.canonicalJSON,
          ])
      }
    }
  }

  func write(snapshot: DBSnapshot, sessionId: String) throws -> Int64 {
    try database.write { db in
      try db.execute(
        sql: """
          INSERT INTO db_snapshots (session_id, taken_at, file_bytes, wal_bytes, row_counts)
          VALUES (?, ?, ?, ?, ?)
          """,
        arguments: [
          sessionId, snapshot.takenAt, snapshot.fileBytes, snapshot.walBytes,
          Self.json(snapshot.rowCounts),
        ])
      return db.lastInsertedRowID
    }
  }

  func write(
    timings: [TimingAggregate], sessionId: String, snapshotId: Int64?, windowStart: Date,
    windowSecs: Int
  ) throws {
    guard !timings.isEmpty else { return }

    try database.write { db in
      for timing in timings {
        try db.execute(
          sql: """
            INSERT INTO timings
              (session_id, snapshot_id, window_start, window_secs, name, tags,
               count, sum_ms, min_ms, max_ms, buckets)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
          arguments: [
            sessionId, snapshotId, windowStart, windowSecs, timing.key.name,
            timing.key.tags.canonicalJSON, timing.count, timing.sumMs, timing.minMs,
            timing.maxMs, Self.json(timing.buckets),
          ])
      }
    }
  }

  func write(statements: [SQLStatementInfo], firstSeen: Date) throws {
    guard !statements.isEmpty else { return }

    try database.write { db in
      for statement in statements {
        try db.execute(
          sql: """
            INSERT OR IGNORE INTO sql_statements (hash, kind, normalized_sql, first_seen)
            VALUES (?, ?, ?, ?)
            """,
          arguments: [statement.hash, statement.kind, statement.normalizedSQL, firstSeen])
      }
    }
  }

  func prune(olderThan cutoff: Date) throws {
    try database.write { db in
      try db.execute(sql: "DELETE FROM timings WHERE window_start < ?", arguments: [cutoff])
      try db.execute(sql: "DELETE FROM spans WHERE started_at < ?", arguments: [cutoff])
    }
  }

  private static func json(_ value: some Encodable) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard let data = try? encoder.encode(value) else { return "null" }
    return String(decoding: data, as: UTF8.self)
  }
}
