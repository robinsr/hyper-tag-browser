// created on 12/12/24 by robinsr

import Foundation
import Testing
import Nimble
import GRDB
import OSLog
import Defaults

@testable import TaggedFileBrowser


extension Tag {
  @Tag static var indexer: Tag
  @Tag static var indexRecord: Tag
  @Tag static var tagRecord: Tag
  @Tag static var dataModel: Tag
  @Tag static var only: Tag
}

typealias RowMap = DatabaseFixtureRow

struct TestSupportFns {
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


struct TestSupportDB {
  static let logger = Logger.newLog(label: "TestSupportDatabase")
  static let debugDumpSeparator = "  |  "
  static let debugDumpFormat = InMemoryFixtureDB.debugDumpFormat
  static let quoteDumpFormat = InMemoryFixtureDB.quoteDumpFormat

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
    
    return try await InMemoryFixtureDB.setupDB(flags)
  }
}
