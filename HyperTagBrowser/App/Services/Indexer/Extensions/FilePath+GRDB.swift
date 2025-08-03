// created on 4/10/25 by robinsr

import GRDB
import System


extension FilePath: @retroactive StatementBinding {}

extension FilePath: @retroactive SQLExpressible {}

extension FilePath: @retroactive DatabaseValueConvertible {
  public var databaseValue: DatabaseValue {
    self.string.databaseValue
  }
  
  public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
    guard let string = String.fromDatabaseValue(dbValue) else { return nil }
    return FilePath(string)
  }
}


extension CodableFilePath: DatabaseValueConvertible {
  public var databaseValue: DatabaseValue {
    self.wrappedValue.string.databaseValue
  }
  
  public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
    guard let dbString = String.fromDatabaseValue(dbValue) else { return nil }
    return CodableFilePath(stringLiteral: dbString)
  }
}
