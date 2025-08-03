// created on 10/29/24 by robinsr

import GRDB
import Factory


enum TextDBFunctions: String, DbFuncDefinition {
  
  case concatGroup, textConcat, textJoin, hashId
  
  var fnName: String { rawValue }
  
  var fnType: DbFuncType {
    switch self {
    case .concatGroup: return .aggregate
    default: return .function
    }
  }
  
  var fnAggregator: DatabaseAggregate.Type? {
    switch self {
    case .concatGroup: return GroupConcatString.self
    default: return nil
    }
  }
  
  var fnArgs: DbFuncArguments {
    switch self {
    case .concatGroup: return .noArgs
    case .textConcat: return .vararg(of: .string)
    case .textJoin: return .vararg(of: .string)
    case .hashId: return .vararg(of: .string)
    }
  }
  
  var fnExec: DbFuncExec? {
    switch self {
    case .textConcat: return Self.execTextConcat
    case .textJoin: return Self.execTextJoin
    case .hashId: return Self.execHashId
    default: return nil
    }
  }
  
  
  /**
   * Concatenates a variable number of strings together
   */
  static let execTextConcat: DbFuncExec = { values in
    values.compactMap { $0 as? String }.joined(separator: "")
  }
  
  
  /**
   * Joins a variable number of strings together, using the first string as a separator.
   */
  static let execTextJoin: DbFuncExec = { dbValues in
    let values = dbValues.compactMap { $0 as? String }
    
    return Array(values.dropFirst()).joined(separator: values[0])
  }
  
  /**
   * Joins any number of string inputs and returns a hash ID based on the concatenated string.
   */
  static let execHashId: DbFuncExec = { dbValues in
    dbValues.compactMap { $0 as? String }.joined(separator: "").hashId
  }
}

struct GroupConcatString: DatabaseAggregate {
  var separator: String = ","
  var values: [String] = []

  mutating func step(_ dbValues: [DatabaseValue]) {
    let newValues = dbValues.compactMap { String.fromDatabaseValue($0) }
    values.append(contentsOf: newValues)
  }

  func finalize() -> (any DatabaseValueConvertible)? {
    return values.joined(separator: separator)
  }
}
