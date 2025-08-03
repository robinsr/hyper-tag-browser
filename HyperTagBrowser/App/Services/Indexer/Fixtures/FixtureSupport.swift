// created on 12/12/24 by robinsr

import Foundation
import GRDB
import Defaults
import OSLog


typealias RowMap = DatabaseFixtureRow

struct FixtureSupportFns {
  static func stringVal(_ key: String) -> (RowMap) -> String {
    return { row in row.stringVal(key) }
  }
  
  static func stringVals(_ cols: String...) -> (RowMap) -> [String] {
    return { row in cols.map(row.stringVal) }
  }
  
  static func contentIdVal(_ key: String) -> (RowMap) -> ContentId {
    return { row in ContentId(existing: row.stringVal(key)) }
  }
  
  static func makeURL(_ base: URL, _ addons: String...) -> URL {
    addons.reduce(base) { $0.appendingPathComponent($1) }
  }
  
  static func areJoined(
    _ itemA: RowMap,
    _ itemB: RowMap,
    inTable: [DatabaseFixtureRow],
    withKeys: (String, String)
  ) -> Bool {
    inTable.contains { row in
      row.stringVal(withKeys.0) == itemA.stringVal("id")
        && row.stringVal(withKeys.1) == itemB.stringVal("id")
    }
  }
}


struct InMemoryFixtureDB {
  static let logger = Logger.newLog(label: "TestSupportDatabase")
  static let debugDumpSeparator = "  |  "
  static let debugDumpFormat = GRDB.JSONDumpFormat(encoder: Constants.prettyJSON)
  static let quoteDumpFormat = GRDB.QuoteDumpFormat(header: true, separator: debugDumpSeparator)
  
  static func setupDB(_ flags: [DevFlags] = []) async throws -> (GRDBIndexService, DatabaseQueue) {
    
      /// Ensure `indexer_debugSqlStatements` is turned off to reduce log noise. Uncomment to enable printing of SQL statements.
    flags.forEach {
      Defaults[.devFlags].toggleExistence($0, shouldExist: true)
    }
    
    let service = try GRDBIndexService(named: .randomIdentifier(12, prefix: "testdb:"))
    let queue = service.dbQueue!
    
//    try service.runMigrations()
//    
//    let verbose = flags.contains(.testing_verboselogs)
//    
//    try await queue.write { db in
//      for record in IndexRecordFixture.records {
//        try record.insert(db)
//      }
//      for record in TagRecordFixture.records {
////        if verbose { print("TagRecordFixture: \(record)") }
//        try record.insert(db)
//      }
//      for record in IndexTagRecordFixture.records {
////        if verbose { print("IndexTagRecordFixture: \(record)") }
//        try record.insert(db)
//      }
//    }
    
//    if verbose {
//      print("🟣 Database contents:")
//      print("    ")
//      try queue.dumpContent(format: Self.debugDumpFormat)
//      
//      try GRDBIndexService.tableNames.forEach { tableName in
//        print("    ")
//        print("🟣 Table: \(tableName)")
//        try queue.dumpTables([tableName], format: Self.debugDumpFormat)
//      }
//      print("    ")
//    }
//    
    
    return (service, queue)
  }
}
