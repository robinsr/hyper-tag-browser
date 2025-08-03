// created on 3/3/25 by robinsr

import Foundation
import System


enum LocalFileServiceError: Error, CustomStringConvertible, LocalizedError {
  case directoryRequiredError
  case resourceValErr(FilePath)
  case renameError(Error)
  case sourceFileNoExist(FilePath)
  case targetDirInvalid(FilePath, String)
  case targetDirNoExist(FilePath)
  case targetFileAlreadyExists(FilePath)
  case zipCreationFailed(FilePath)
  
  
  var message: String {
    switch self {
    case .directoryRequiredError:
      return "A directory is required for this operation."
    case .resourceValErr(let path):
      return "Invalid resource value at path: \(path.string)"
    case .renameError(let error):
      return "File move failed: \(error.localizedDescription)"
    case .sourceFileNoExist(let path):
      return "Source file does not exist at path: \(path.string)"
    case .targetDirInvalid(let path, let message):
      return "Target directory invalid (\(message)): \(path.string)"
    case .targetDirNoExist(let path):
      return "Target directory does not exist at path: \(path.string)"
    case .targetFileAlreadyExists(let path):
      return "File already exists at path: \(path.string)"
    case .zipCreationFailed(let path):
      return "Failed to create zip file at path: \(path.string)"
    }
  }
  
  var description: String {
    return message
  }
  
  var errorDescription: String? {
    return message
  }
  
  var error: Error? {
    switch self {
    case .renameError(let error):
      return error
    case .directoryRequiredError,
         .resourceValErr,
         .sourceFileNoExist,
         .targetDirInvalid,
         .targetDirNoExist,
         .targetFileAlreadyExists,
         .zipCreationFailed:
      return self
    }
  }
}
