// created on 4/8/25 by robinsr

import CoreSpotlight


enum SearchState: Equatable, Hashable, CustomStringConvertible {
  case ready
  case searching
  case returned(results: [CSSearchableItem])
  case errorMessage(String)
  case errorCode(Int)
  
  var description: String {
    switch self {
    case .ready: 
      return "Ready"
    case .searching:
      return "Searching"
    case .returned(let results):
      return "Returned(results: \(results.count))"
    case .errorMessage(let msg):
      return "Error(message: \(msg))"
    case .errorCode(let code):
      return "Error(code: \(code))"
    }
  }
  
  var resultCount: Int {
    switch self {
    case .returned(let results): return results.count
    default: return 0
    }
  }
  
  var isLoading: Bool {
    if case .searching = self {
      return true
    } else {
      return false
    }
  }
  
  var isError: Bool {
    switch self {
    case .errorMessage(_), .errorCode(_): return true
    default: return false
    }
  }
  
  var errorMessage: String? {
    switch self {
    case .errorMessage(let msg):
      return msg
    case .errorCode(let code):
      if let queryErrCode = CSSearchQueryError.Code(rawValue: code) {
        return CSSearchQueryError(queryErrCode).localizedDescription
      }
      
      if let indexErrCode = CSIndexError.Code(rawValue: code) {
        return CSIndexError(indexErrCode).localizedDescription
      }
      
      return "Unknown Error Code: \(code)"
    default:
      return nil
    }
  }
}


/*
 public struct CSSearchQueryError : CustomNSError, Hashable, Error {
     public init(_nsError: NSError)
     public static var errorDomain: String { get }
     @available(macOS 10.13, *)
     public enum Code : Int, @unchecked Sendable, Equatable {
         public typealias _ErrorType = CSSearchQueryError
         case unknown = -2000
         case indexUnreachable = -2001
         case invalidQuery = -2002
         case cancelled = -2003
     }
     public static var unknown: CSSearchQueryError.Code { get }
     public static var indexUnreachable: CSSearchQueryError.Code { get }
     public static var invalidQuery: CSSearchQueryError.Code { get }
     public static var cancelled: CSSearchQueryError.Code { get }
 }
 */
