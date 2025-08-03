// created on 10/22/24 by robinsr

import GRDB
import Factory
import Regex


enum RegexpDBFunctions: String, DbFuncDefinition {
  
  private static let logger = EnvContainer.shared.logger("RegexpDBFunctions")
  
  case regexpMatch, regexpCapture, regexpReplace
  
  var fnName: String { return self.rawValue }
  var fnType: DbFuncType { return .function }
  var fnAggregator: DatabaseAggregate.Type? { return nil }
  
  var fnArgs: DbFuncArguments {
    switch self {
    case .regexpMatch:   return .fixed(of: [.string, .string])
    case .regexpCapture: return .fixed(of: [.string, .string, .integer])
    case .regexpReplace: return .fixed(of: [.string, .string, .string])
    }
  }
  
  var fnExec: DbFuncExec? {
    switch self {
    case .regexpMatch: return Self.execRegexpMatch
    case .regexpCapture: return Self.execRegexpCapture
    case .regexpReplace: return Self.execRegexpReplace
    }
  }
  
  static let execRegexpMatch: DbFuncExec = { values in
    guard let dbValue = values[0] as? String else { return nil }
    guard let pattern = values[1] as? String else { return nil }
    
    do {
      let regexp = try Regex(string: pattern)
      return regexp.matches(dbValue)
    } catch {
      logger.emit(.error, ErrorMsg("Invalid regexp pattern in SQL statement: \(pattern)", error))
    }
    
    return nil
  }
  
  /// `SELECT regexp_capture(name, '\[(.*)\]', 0) as attribution`
  static let execRegexpCapture: DbFuncExec = { values in
    guard let dbValue = values[0] as? String else { return nil }
    guard let pattern = values[1] as? String else { return nil }
    guard let index = values[2] as? Int else { return nil }
  
    do {
      let regexp = try Regex(string: pattern)
      let matchResult = regexp.firstMatch(in: dbValue)
      
      if let capture = matchResult?.captures[safe: index] { return capture }
      return nil
    } catch {
      logger.emit(.error, ErrorMsg("Invalid regexp pattern in SQL statement: \(pattern)", error))
    }
    
    return nil
  }
  
  static let execRegexpReplace: DbFuncExec = { values in
    guard let dbValue = values[0] as? String else { return nil }
    guard let pattern = values[1] as? String else { return nil }
    guard let replace = values[2] as? String else { return nil }
  
    do {
      let regexp = try Regex(string: pattern)
      let matchResult = regexp.firstMatch(in: dbValue)
      
      if let capture = matchResult?.captures.first { return replace }
      if let matched = matchResult?.matchedString { return replace }
    } catch {
      logger.emit(.error, ErrorMsg("Invalid regexp pattern in SQL statement: \(pattern)", error))
    }
    
    return nil
  }
}

