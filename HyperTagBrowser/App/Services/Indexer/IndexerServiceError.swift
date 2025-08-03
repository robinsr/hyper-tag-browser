// created on 6/2/25 by robinsr

import Foundation

enum IndexerServiceError: Error, CustomStringConvertible {

  /// Indicates that the database location is invalid, or otherwise could not be loaded
  case DatabaseNotFound(URL, attributes: [String: Any]? = nil)
  
  /// Indicates that an ID was not found in the database
  case IdNotFound(String, attributes: [String: Any]? = nil)

  /// Indicates an error occurred during database initialization or migration
  case InitializationError(Error, attributes: [String: Any]? = nil)

  /// Indicates an unexpected scenario where the database is in an inconsistent state
  case DataIntegrityError(String, attributes: [String: Any]? = nil)

  /// Thrown when a parameter passed to a function is invalid or out of expected range
  case InvalidParameter(String, attributes: [String: Any]? = nil)

  /// Thrown when a database operation fails unexpectedly, such as a failed insert or update
  case OperationFailed(String, err: Error? = nil, attributes: [String: Any]? = nil)

  var description: String {
    switch self {

      case .DatabaseNotFound(let url, _):
        return "Database not found at \(url.path)"
      
      case .IdNotFound(let id, _):
        return "ID not found in database: \(id)"

      case .InitializationError(let error, _):
        return "Database init error: \(error.localizedDescription)"

      case .DataIntegrityError(let message, _):
        return "Data integrity error: \(message)"

      case .InvalidParameter(let message, _):
        return "Invalid parameter: \(message)"

      case .OperationFailed(let message, let err, _):
        if let error = err {
          return "Operation failed: \(message), error: \(error.localizedDescription)"
        } else {
          return "Operation failed: \(message)"
        }
    }
  }

  var originalError: Error? {
    switch self {
      case .InitializationError(let error, _): error
      case .OperationFailed(_, let error, _): error
      default: nil
    }
  }

  var asNSError: NSError {
    let attributes =
      switch self {
        case .DatabaseNotFound(_, let attributes),
          .IdNotFound(_, let attributes),
          .InitializationError(_, let attributes),
          .DataIntegrityError(_, let attributes),
          .InvalidParameter(_, let attributes),
          .OperationFailed(_, _, let attributes):
          attributes ?? [:]
      }

    var userInfo: [String: Any] = [
      NSLocalizedFailureReasonErrorKey: self.description,
      NSLocalizedRecoverySuggestionErrorKey: "Please check the database or parameters.",
    ]

    for attr in attributes {
      userInfo[attr.key] = attr.value
    }

    return NSError(domain: "IndexerServiceError", code: self.errorCode, userInfo: userInfo)
  }
}

extension IndexerServiceError: CustomNSError {
  public static var errorDomain: String {
    return "IndexerServiceError"
  }

  public var errorCode: Int {
    switch self {
      case .DatabaseNotFound: 404          // Not Found
      case .IdNotFound: 404                // Not Found
      case .InitializationError: 500          // Internal Server Error
      case .DataIntegrityError: 500          // Internal Server Error
      case .InvalidParameter: 400          // Bad Request
      case .OperationFailed: 500          // Internal Server Error
    }
  }

  public var errorUserInfo: [String: Any] {
    asNSError.userInfo
  }
}

extension IndexerServiceError: LocalizedError {
  public var errorDescription: String? {
    return self.description
  }

  public var failureReason: String? {
    switch self {
      case .DatabaseNotFound:
        return "The specified database could not be found."
      case .IdNotFound:
        return "The specified ID does not exist in the database."
      case .InitializationError:
        return "An error occurred during database initialization."
      case .DataIntegrityError:
        return "The database is in an inconsistent state."
      case .InvalidParameter:
        return "One or more parameters are invalid."
      case .OperationFailed:
        return "A database operation failed unexpectedly."
    }
  }
}
