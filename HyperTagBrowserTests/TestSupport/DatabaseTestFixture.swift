// created on 12/14/24 by robinsr

import Foundation
import GRDB
import System

@testable import TaggedFileBrowser


/// Maps column names to fixture values
typealias DatabaseFixtureRow = [String : GRDB.DatabaseValue]


/// Expresses the association between a row in the primary table, and
/// the rows in the one or more other tables that are associated with it.
typealias AssociatedFixtureMap = [String : [DatabaseFixtureRow]]


enum DatabaseFixtureError: Error, Sendable {
  case badTypeConversion(String, String)
}


/// Utility methods for fetching values from a fixture map
extension DatabaseFixtureRow {
  func string(for key: String) throws(DatabaseFixtureError) -> String {
    guard let value = self[key]?.storage.value as? String else {
      throw .badTypeConversion("String", key)
    }
    return value
  }
  
  func url(for key: String) throws(DatabaseFixtureError) -> URL {
    URL(filePath: try string(for: key))
  }
  
  func filepath(for key: String) throws(DatabaseFixtureError) -> FilePath {
    FilePath(try string(for: key))
  }
  
  func contentId(for key: String) throws(DatabaseFixtureError) -> ContentId {
    ContentId(existing: try string(for: key))
  }
  
    /// Maps Record types to test fixtures of that type
  struct Association: Sendable {
    
    /// The record/row in the primary table
    var fixtureRow: DatabaseFixtureRow
    
    /// A map of rows in tables associated with the primary table
    var fixtureMap: AssociatedFixtureMap
    
    init(_ row: DatabaseFixtureRow, _ associations: AssociatedFixtureMap) {
      self.fixtureRow = row
      self.fixtureMap = associations
    }
  }
}



protocol DBTestCase: RawRepresentable where RawValue == String {
  var id: String { get }
  var asRow: DatabaseFixtureRow { get }
}


/// The primary protocol for defining test fixtures for a database table (aka a `RecordType`)
protocol DatabaseTestFixtureType: Sendable {
  associatedtype RecordType: PersistableRecord
  
  static var data: [DatabaseFixtureRow] { get }
  static var associations: [DatabaseFixtureRow.Association] { get }
  static var dbRows: [GRDB.Row] { get }
  static var records: [RecordType] { get }
  static var ids: [String] { get }
  static func withId(_ id: String) -> DatabaseFixtureRow?
}
