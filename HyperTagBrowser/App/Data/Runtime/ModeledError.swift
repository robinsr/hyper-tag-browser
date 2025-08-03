// created on 11/12/24 by robinsr

import Foundation


enum ModeledError: Error, CustomStringConvertible, LocalizedError {
  
  // Domain-specific Modeled Errors:
  
  @available(*, deprecated, message: "Too vague; use more-specific error types instead")
  case grdb(String)
  case duplicateContentFound(pointers: [ContentPointer])
  case expectedContentIdMissing(forFile: URL)
  case clearThumbnailCache(Error)
  
  // Domain-agnostic Errors
  
  case unmodeled(Error)
  case failed(to: String, fallback: String? = nil, error: Error? = nil, reason: String? = nil)
  
  
  func with(error newError: Error) -> ModeledError {
    switch self {
    case .failed(let task, let fb, _, let ctx):
      return .failed(to: task, fallback: fb, error: newError, reason: ctx)
    default:
      return self
    }
  }
  
  func with(reason exp: String) -> ModeledError {
    switch self {
    case .failed(let task, let fb, let err, _):
      return .failed(to: task, fallback: fb, error: err, reason: exp)
    default:
      return self
    }
  }
  
  
  var className: String {
    let clz = String(describing: type(of: self))
    return "\(clz.hasSuffix("Error") ? String(clz.dropLast(5)) : clz)"
  }
  
  var name: String {
    switch self {
    case .clearThumbnailCache(_): "clearThumbnailCache"
    case .duplicateContentFound(_): "duplicateContentFound"
    case .grdb(_): "grdb"
    case .unmodeled(_): "unmodeled"
    case .expectedContentIdMissing(_): "expectedContentIdMissing"
    case .failed(_,_,_,_): "failed(to:fallback:err:reason:)"
    }
  }
  
  var rawValue: String { "\(className).\(name)" }
  
  var errorDescription: String? {
    NSLocalizedString(self.message, comment: self.description)
  }
  
  var error: Error? {
    switch self {
    case .unmodeled(let error),
         .clearThumbnailCache(let error): return error
    default: return nil
    }
  }

  
  /**
   Variable string message for the error.
   */
  var message: String {
    switch self {
    case .clearThumbnailCache(let err):
      return "\(description); \(err.legibleDescription)"
    
    case .duplicateContentFound(let pointers):
      return "\(description); Content pointers: [\(pointers.ids)]"
    
    case .unmodeled(let error):
      return error.localizedDescription.isEmpty ? "An unknown error occurred" : error.localizedDescription
    
    case .expectedContentIdMissing(let file):
      return "Expected to find a contentId extended attribute on file: \(file.filepath.string); None was found"
    
    case .failed(to: let task, fallback: let fallback, _, let reason):
      var msgParts = ["Failed to \(task)"]
      
      if let explanation = reason {
        msgParts.append("(\(explanation))")
      }
      
      if let method = fallback {
        msgParts.append("Falling back to \(method)")
      }
      
      return msgParts.joined(separator: " ")
      
    case .grdb(let msg):
      return msg
    
    default:
       return "No message available for this error type (\(rawValue))"
    }
  }
  
  
  /**
   * Static description of the type of error (instance-specific context omitted)
   */
  var description: String {
    switch self {
    case .clearThumbnailCache(_):
      "Failed to clear thumbnail cache"
    case .duplicateContentFound(_):
      "Duplicate ContentIds encountered"
    case .grdb(_):
      "A problem occurred with the database"
    case .unmodeled(_):
       "Error type unmodeled"
    case .failed(_,_,_,_):
       "Tasked failed in some expected way"
    default:
       "No description provided for this error type (\(rawValue))"
    }
  }
}
