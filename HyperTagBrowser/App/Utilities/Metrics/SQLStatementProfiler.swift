// created on 10/26/26 by robinsr

import Foundation
import GRDB
import Synchronization

/// Receives GRDB `.profile` trace events and records each statement's duration as a `sql`
/// timing tagged with the statement hash and connection kind.
///
/// The duration is SQLite's profile value: wall-clock from first step to reset, which includes
/// GRDB decoding rows between steps.
final class SQLStatementProfiler: Sendable {
  static let cacheLimit = 10_000

  private let recorder: any MetricsRecorder
  private let connection: String
  private let logToConsole: Bool
  private let logger = CustomLogger("SQLStatementProfiler", level: .debug)
  private let cache = Mutex<[String: SQLStatementInfo]>([:])

  init(recorder: any MetricsRecorder, connection: String, logToConsole: Bool = false) {
    self.recorder = recorder
    self.connection = connection
    self.logToConsole = logToConsole
  }

  func handle(_ event: Database.TraceEvent) {
    guard case .profile(let statement, let duration) = event else { return }
    record(sql: statement.sql, duration: duration)
  }

  func record(sql: String, duration: TimeInterval) {
    let info = statementInfo(for: sql)
    let ms = duration * 1_000

    recorder.timing("sql", ms: ms, tags: ["stmt": info.hash, "conn": connection])

    if logToConsole {
      logger.emit(.debug, "\(String(format: "%.3f", ms))ms [\(info.hash)] \(info.normalizedSQL)")
    }
  }

  /// Normalizing runs a regex, so results are cached by raw SQL text.
  private func statementInfo(for sql: String) -> SQLStatementInfo {
    if let cached = cache.withLock({ $0[sql] }) {
      return cached
    }

    let info = SQLNormalizer.info(for: sql)

    cache.withLock { cache in
      if cache.count >= Self.cacheLimit {
        cache.removeAll()
      }
      cache[sql] = info
    }

    recorder.register(statement: info)

    return info
  }
}
