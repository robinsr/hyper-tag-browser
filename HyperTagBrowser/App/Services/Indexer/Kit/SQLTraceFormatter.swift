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
  
  func formatAndPrint(_ sql: Database.TraceEvent) {
    filelog.info("\(sql.description) \(logSeparator)")
  }
  
  func formatEvent(string sql: String) -> String {
    let terms = SQLTerms.allCases
    let termValues = SQLTerms.values
    
    var lines = sql.replacingAll(matching: #"\s+"#, with: " ")
    var out = ""
    
    while lines.count > 0 {
      
      for term in terms {
        if term.matchFront(of: lines) {
          out += term.format(from: lines, newline: newlineChar)
          lines = term.removing(from: lines)
        }
      }
      
      lines = lines.trimmingCharacters(in: .whitespaces)
      
      if lines.contains(any: termValues) {
        
        let distanceMap = TermDistanceMap(lines)
        let interSql = String(lines.prefix(distanceMap.closest.0))
        
        out += interSql
        out += "\(newlineChar)"
        
        lines.removeFirst(interSql.count)
      }
      
      else if lines.notEmpty {
        out += lines
        lines = ""
      }
    }
    
    return out.replacingAll(matching: #"(\n){2,}"#, with: "\n")
  }
  
  func skipStatement(_ evt: Database.TraceEvent) -> Bool {
    if !Self.tableNames(evt).contains(any: enabledTables) {
      return true
    } else {
      return evt.description.contains(any: Self.skipSQLTerms)
    }
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
  
  enum SQLTerms: String, CaseIterable {
    case INSERT_REPL = "INSERT OR REPLACE INTO "
    case SELECT = "SELECT "
    case DELETE = "DELETE FROM "
    case INSERT = "INSERT INTO "
    
    case VALUES = " VALUES "
    case FROM   = " FROM "
    case WHERE  = " WHERE "
    case XWHERE  = "WHERE"
    case LEFT   = " LEFT JOIN "
    case RIGHT  = " RIGHT JOIN "
    case INNER  = " INNER JOIN "
    case OUTER  = " OUTER JOIN "
    case JOIN   = " JOIN "
    
    case AND1   = " AND 1 "
    case ZAND1  = " 1 AND "
    case ZAND   = ") AND ("
    case XAND   = ") AND "
    case YYAND  = " AND "
    case YAND   = " AND"
    case AAAND  = "AND "
    
    case ORDER  = " ORDER BY "
    case GROUP  = " GROUP BY "
    case LIMIT  = " LIMIT "
    case DESC   = " DESC"
    case ASC    = " ASC"
    
    case OR     = " OR "
    case ON     = " ON "
    
    var name: String {
      self.rawValue
        .trimmingCharacters(in: .alphanumerics.inverted)
        .trimmingCharacters(in: .whitespaces)
    }
    
    var isAND: Bool {
      self.oneOf(.AAAND, .XAND, .YAND, .YYAND, .ZAND, .AND1, .ZAND1)
    }
    
    var capturesCloseParenthesis: Bool {
      self.rawValue.first == ")"
    }
    
    var capturesOpenParenthesis: Bool {
      self.rawValue.last == "("
    }
    
    var pattern: String {
      return #"\#(self.rawValue)"#
    }
    
    var regex: Regex {
      return try! Regex(
        string: self.pattern,
        options: [.dotMatchesLineSeparators, .ignoreMetacharacters]
      )
    }
    
    
    /**
     Returns a regex that matches inputs starting with the term
     */
    var headMatch: Regex {
      let escaped = self.rawValue
        .replacingOccurrences(of: "(", with: "\\(")
        .replacingOccurrences(of: ")", with: "\\)")
        .replacingOccurrences(of: " ", with: "\\s")
      
      return try! Regex(string: #"^(?:[\s]+)?\#(escaped)"#)
    }
    
    /**
     Captures all characters before the term
     */
    var leadingCapture: Regex {
      let escaped = self.rawValue
        .replacingOccurrences(of: "(", with: "\\(")
        .replacingOccurrences(of: ")", with: "\\)")
        .replacingOccurrences(of: " ", with: "\\s")
      
      return try! Regex(string: #"(.*)\#(escaped)"#)
    }
    
    
    func firstMatchDistance(in str: String) -> Int? {
      leadingCapture.firstMatch(in: str)?.captures.first??.count
    }
    
    func select(from str: String) -> String? {
      regex.firstMatch(in: str)?.matchedString
    }
    
    
    
    
    var newLineAfter: Bool {
      return rawValue.last?.isWhitespace ?? false
    }
    
    var newLineBefore: Bool {
      if self.oneOf(.WHERE, .XWHERE) {
        return true
      }
      
      return rawValue.first?.isWhitespace ?? false
    }

    
    func format(from str: String, newline: Character = "\n") -> String {
      var trimmed = self.rawValue.trimmingCharacters(in: .whitespaces)
      
      if self == .SELECT {
        var remainingLine = str
        remainingLine.removeFirst(self.rawValue.count)
        
        let nexts = TermDistanceMap(remainingLine)
        
        let fullStatement = String(remainingLine.prefix(nexts.closest.0))

        Self.columnSelections.allMatches(in: fullStatement).forEach { match in
          trimmed += "\(newline)    \(match.matchedString)"
        }
        
        // return "__SELECT__[\(trimmed)]\(newline)\(newline)"
        return trimmed
      }
      
      if self.oneOf(.AND1, .ZAND1, .AAAND) {
        return "\(trimmed)\(newline)    "
      }
      
      
      if self.isAND {
        return "\(newline)\(trimmed)\(newline)    "
      }
      
      trimmed = "\(newLineBefore ? "\(newline)" : "")\(trimmed)\(newLineAfter ? "\(newline)    " : "")"
      
      // return "__\(self.rawValue)__[\(trimmed)]\(newline)\(newline)"
      return trimmed
      
    }
    
    func removing(from str: String) -> String {
      var removed = str.replacingFirst(matching: self.regex, with: "")
      
      if self == .SELECT {
        let next = TermDistanceMap(removed)
        removed.removeFirst(next.closest.0)
      }
      
      return removed
    }
    
    func matchFront(of str: String) -> Bool {
      headMatch.matches(str)
    }
    
    static var values: [String] {
      SQLTerms.allCases.map(\.rawValue)
    }
    
    static var columnSelections: Regex {
      let sqliteFnNames = [
        "ABS", "CHANGES", "CHAR", "COALESCE", "CONCAT", "CONCAT_WS", "FORMAT", "GLOB", "HEX", "IFNULL", "IIF",
        "INSTR", "LAST_INSERT_ROWID", "LENGTH", "LIKE", "LIKE", "LIKELIHOOD", "LIKELY", "LOAD_EXTENSION", "LOAD_EXTENSION", "LOWER", "LTRIM",
        "LTRIM", "MAX", "MIN", "NULLIF", "OCTET_LENGTH", "PRINTF", "QUOTE", "RANDOM", "RANDOMBLOB", "REPLACE", "ROUND", "ROUND",
        "RTRIM", "RTRIM", "SIGN", "SOUNDEX", "SUBSTR", "SUBSTR", "SUBSTRING", "SUBSTRING", "TOTAL_CHANGES", "TRIM", "TRIM",
        "TYPEOF", "UNHEX", "UNHEX", "UNICODE", "UNLIKELY", "UPPER", "ZEROBLOB"
      ]
      
      let fns = (sqliteFnNames + DatabaseFunctions.functionNames).joined(separator: "|")
      
      return try! Regex(
        string: #"((?<func>(\#(fns))\([^AS]*\) AS "(?<var>\w+)")|(?<tablecol>(?<!AS\s)\"[\w\.\"]+\"( AS "\w+")?)|\d AS "[\w\.\"]+\"),?"#
      )
    }
  }
  
  struct TermDistanceMap {
    
    private var elements = Dictionary<SQLTerms, Int>()
    
    init(_ str: String) {
      elements = Dictionary(uniqueKeysWithValues: SQLTerms.allCases.map { term in
        (term, term.firstMatchDistance(in: str) ?? str.count)
      })
    }
    
    var closest: (Int, SQLTerms) {
      let item = elements.min { $0.value < $1.value }!
      
      return (item.value, item.key)
    }
  }
}

extension Regex: @unchecked @retroactive Sendable {}
