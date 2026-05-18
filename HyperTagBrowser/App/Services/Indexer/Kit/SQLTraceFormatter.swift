// created on 12/13/24 by robinsr

import Foundation
import Factory
import GRDB
import Regex
import CustomDump
import OSLog
import XCGLogger


struct SQLTraceFormatter {
  private let logger = EnvContainer.shared.logger("SQLTraceFormatter")
  
  private let formatter = SQLQueryFormatter(namespace: "SQLTraceFormatter")
  
  private let filelog = {
    let logger = XCGLogger(identifier: "sql_trace_log", includeDefaultDestinations: false)
    
    let logFile = FileDestination(
      writeToFile: UserLocation.desktop.appending(path: "sql_trace.log"),
      identifier: "advancedLogger.fileDestination"
    )
    
    logFile.outputLevel = .info
    logFile.showLogIdentifier = false
    logFile.showFunctionName = false
    logFile.showThreadName = false
    logFile.showLevel = false
    logFile.showFileName = false
    logFile.showLineNumber = false
    logFile.showDate = true
    
    logger.add(destination: logFile)
    logger.logAppDetails()
    
    return logger
  }()
  
  private let tabChar: Character = "\t"
  private let newlineChar: Character = "\n"
  private let logSeparator = "\n" + String(repeating: "-", count: 25) + "\n"
  
  var enabledTables: [String]
  
  init(enabledTables: [String]) {
    self.enabledTables = enabledTables
  }
  
  func skipStatement(_ evt: Database.TraceEvent) -> Bool {
    if !Self.tableNames(evt).contains(any: enabledTables) {
      return true
    } else {
      return evt.description.contains(any: Self.skipSQLTerms)
    }
  }
  
  func formatAndPrint(_ sql: Database.TraceEvent) {
    filelog.info("\(sql.description) \(logSeparator)")
  }
  
  static func tableNames(_ evt: Database.TraceEvent) -> [String] {
    var tables: Set<String> = []
    
    for pattern in queryTablePattern {
      if let matches = pattern.allMatches(in: evt.expandedDescription).nilIfEmpty {
        for match in matches {
          if let value = match.captures[safe: 0], let unwrapped = value {
            tables.insert(unwrapped)
          }
        }
      }
    }
    
    return tables.asArray
  }
  
  static let queryTablePattern: [Regex] = [
    .init(#"FROM "?([a-zA-Z0-9_]+)"?"#),
    .init(#"INTO "?([a-zA-Z0-9_]+)"?"#),
    .init(#"(LEFT|RIGHT|INNER|OUTER)? JOIN "?([a-zA-Z0-9_]+)"?"#),
  ]
  
  static let skipSQLTerms = [
    "PRAGMA",
    "PRAGMA query_only",
    "PRAGMA schema_version",
    "PRAGMA main.table_xinfo",
    "PRAGMA main.index_info",
    "PRAGMA main.index_list",
    "PRAGMA main.index_xinfo",
    "SELECT * FROM sqlite_master LIMIT 1",
    "BEGIN",
    "BEGIN DEFERRED TRANSACTION",
    "COMMIT",
    "COMMIT TRANSACTION",
    "CREATE",
    "CREATE TABLE ",
    " CREATE TABLE "
  ]
}

extension Regex: @unchecked @retroactive Sendable {}
