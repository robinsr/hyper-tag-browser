// created on 10/14/24 by robinsr

import GRDB
import UniformTypeIdentifiers

extension UTType: @retroactive StatementBinding {}

extension UTType: @retroactive SQLExpressible {}

extension UTType: @retroactive DatabaseValueConvertible {
  public var databaseValue: DatabaseValue {
    DatabaseValue(value: self.identifier)!.databaseValue
  }
  
  public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
    guard let stringValue = String.fromDatabaseValue(dbValue) else {
      return nil
    }
    return UTType(stringValue)
  }
}
