// created on 10/26/26 by robinsr

import Foundation

/// One app launch.
struct MetricsSession: Equatable, Sendable {
  let id: String
  let startedAt: Date
  let appVersion: String
  let buildNumber: String
  let osVersion: String
  let mainDbName: String
}


/// Size of the main index database at a point in time.
struct DBSnapshot: Equatable, Sendable {
  let takenAt: Date
  let fileBytes: Int64
  let walBytes: Int64
  let rowCounts: [String: Int]
}


/// A normalized SQL statement, keyed by its stable hash.
struct SQLStatementInfo: Hashable, Sendable {
  let hash: String
  let kind: String
  let normalizedSQL: String
}


/// Destination for flushed metrics. `SQLiteMetricsSink` is the only implementation today;
/// a StatsD sink would be a second one.
protocol MetricsSink: Sendable {
  func begin(session: MetricsSession) throws
  func end(sessionId: String, at date: Date) throws
  func write(spans: [SpanRecord], sessionId: String) throws
  func write(snapshot: DBSnapshot, sessionId: String) throws -> Int64
  func write(
    timings: [TimingAggregate], sessionId: String, snapshotId: Int64?, windowStart: Date,
    windowSecs: Int) throws
  func write(statements: [SQLStatementInfo], firstSeen: Date) throws
  func prune(olderThan cutoff: Date) throws
}
