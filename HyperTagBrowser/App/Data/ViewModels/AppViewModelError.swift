// created on 6/3/25 by robinsr

import Foundation


enum AppViewModelError: Error, CustomStringConvertible {
  case AssociationError(Error)
  case TooLazyToDefineError(String)
  case NotImplemented(String)
  case NotAllowed(String)
  case ContentNotFound(ContentPointer)
  case ObjectNotFound(id: String)
  
  var description: String {
    switch self {
    case .AssociationError(let error):
      return "Error associating tag: \(error.localizedDescription)"
    case .TooLazyToDefineError(let message):
      return message
    case .NotImplemented(let message):
      return "Not implemented: \(message)"
    case .NotAllowed(let message):
      return "Not allowed: \(message)"
    case .ContentNotFound(let pointer):
      return "Content not found: \(pointer.contentId)"
    case .ObjectNotFound(let id):
      return "Object not found with ID: \(id)"
    }
  }
  
  
  static let globalTag: AppViewModelError = .NotAllowed("Cannot apply a tag globally")
  static let paramBasedTagging: AppViewModelError = .NotImplemented("Parameter-based tagging not yet supported")
  static let exBasedTagging: AppViewModelError = .NotImplemented("Exclusion-based tagging not yet supported")
  static let urlBasedTagging: AppViewModelError = .NotImplemented("URL-based tagging not yet supported")
}
