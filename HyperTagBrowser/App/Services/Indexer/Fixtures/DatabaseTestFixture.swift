// created on 12/14/24 by robinsr// created on 12/14/24 by robinsr

import Foundation
import GRDB


/// Maps column names to fixture values
typealias DatabaseFixtureRow = [String : (any DatabaseValueConvertible)?]


/// Utility methods for fetching values from a fixture map
extension DatabaseFixtureRow {
  func stringVal(_ key: String) -> String {
    guard let value = self[key] as? String else {
      fatalError("Expected string value for key '\(key)'")
    }
    return value
  }
  
  func urlVal(_ key: String) -> URL {
    guard let value = self[key] as? URL else {
      fatalError("Expected string value for key '\(key)'")
    }
    return value
  }
  
  func contentId(_ key: String) -> ContentId {
    ContentId(existing: stringVal(key))
  }
  
    /// Maps Record types to test fixtures of that type
  struct Association {
    
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


/// Expresses the association between a row in the primary table, and
/// the rows in the one or more other tables that are associated with it.
typealias AssociatedFixtureMap = [String : [DatabaseFixtureRow]]



protocol DBTestCase: RawRepresentable where RawValue == String {
  var id: String { get }
  var asRow: DatabaseFixtureRow { get }
}


/// The primary protocol for defining test fixtures for a database table (aka a `RecordType`)
protocol DatabaseTestFixtureType {
  associatedtype RecordType: PersistableRecord
  
  static var data: [DatabaseFixtureRow] { get }
  
  static var associations: [DatabaseFixtureRow.Association] { get }
  
  static var dbRows: [GRDB.Row] { get }
  
  static var records: [RecordType] { get }
  
  static var ids: [String] { get }
  
  static func withId(_ id: String) -> DatabaseFixtureRow?
}


//  /// Maps Record types to test fixtures of that type
//struct DatabaseFixtureRowAssociation {
//  
//  /// The record/row in the primary table
//  var fixtureRow: DatabaseFixtureRow
//  
//  /// A map of rows in tables associated with the primary table
//  var fixtureMap: AssociatedFixtureMap
//  
//  init(_ row: DatabaseFixtureRow, _ associations: AssociatedFixtureMap) {
//    self.fixtureRows = row
//    self.fixtureMap = associations
//  }
//}
