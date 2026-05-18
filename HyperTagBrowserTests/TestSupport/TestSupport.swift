// created on 12/12/24 by robinsr

import Foundation
import Testing
import Nimble
import GRDB
import OSLog
import Defaults

@testable import HyperTagBrowser


extension Tag {
  @Tag static var indexer: Tag
  @Tag static var indexRecord: Tag
  @Tag static var tagRecord: Tag
  @Tag static var dataModel: Tag
  @Tag static var only: Tag
}


struct TestSupportDB {
  static let logger = Logger.newLog(label: "TestSupportDatabase")
  static let debugDumpSeparator = "  |  "
  static let debugDumpFormat = GRDB.JSONDumpFormat(encoder: Constants.prettyJSON)
  static let quoteDumpFormat = GRDB.QuoteDumpFormat(header: true, separator: debugDumpSeparator)

  static func setupDB(_ flags: DevFlags...) async throws -> (GRDBIndexService, DatabaseQueue) {
    
    /// Ensure `indexer_debugSqlStatements` is turned off to reduce log noise. Uncomment to enable printing of SQL statements.
    flags.forEach {
      Defaults[.devFlags].toggleExistence($0, shouldExist: true)
    }
    
    var testTags: Set<Tag> = []
    
    if let currentTest = Test.current {
      testTags = currentTest.tags
      
      currentTest.tags.contains(.only) ? print("🔴 Running ONLY test") : nil
    }
    
    if testTags.contains(.only) {
      Defaults[.devFlags].insert(.testing_verboselogs)
    }
    
    let dbName = String.randomIdentifier(12, prefix: "testdb:")
    let queue = try DatabaseQueue(named: dbName, configuration: GRDBIndexService.configure())
    let service = GRDBIndexService(database: queue)
    
    try service.runMigrations()

    let verbose = true // flags.contains(.testing_verboselogs)

    try await queue.write { db in
      for record in IndexRecordFixture.records {
        if verbose { print("IndexRecordFixture: \(record)") }
        try record.insert(db)
      }
      for record in TagRecordFixture.records {
        if verbose { print("TagRecordFixture: \(record)") }
        try record.insert(db)
      }
      for record in IndexTagRecordFixture.records {
        if verbose { print("IndexTagRecordFixture: \(record)") }
        try record.insert(db)
      }
    }
    
    if verbose {
      print("🟣 Database contents:")
      print("    ")
      try queue.dumpContent(format: Self.debugDumpFormat)

      try SchemaConfiguration.tableNames.forEach { tableName in
        print("    ")
        print("🟣 Table: \(tableName)")
        try queue.dumpTables([tableName], format: Self.debugDumpFormat)
      }
      print("    ")
    }
        
    return (service, queue)
  }
}
