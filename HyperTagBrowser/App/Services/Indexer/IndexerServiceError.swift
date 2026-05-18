// created on 6/2/25 by robinsr

import Foundation

enum IndexerServiceError: Error, CustomStringConvertible, Sendable {

  /// Indicates that the database location is invalid, or otherwise could not be loaded
  case DatabaseNotFound(URL)
  
  /// Indicates that an ID was not found in the database
  case IdNotFound(String)

  /// Indicates an error occurred during database initialization or migration
  case InitializationError(Error)

  /// Indicates an unexpected scenario where the database is in an inconsistent state
  case DataIntegrityError(String)

  /// Thrown when a parameter passed to a function is invalid or out of expected range
  case InvalidParameter(String)

  /// Thrown when a database operation fails unexpectedly, such as a failed insert or update
  case OperationFailed(String, err: Error? = nil)
  
  case searchFailed(String)

  var description: String {
    switch self {

      case .DatabaseNotFound(let url):
        return "Database not found at \(url.path)"
      
      case .IdNotFound(let id):
        return "ID not found in database: \(id)"

      case .InitializationError(let error):
        return "Database init error: \(error.localizedDescription)"

      case .DataIntegrityError(let message):
        return "Data integrity error: \(message)"

      case .InvalidParameter(let message):
        return "Invalid parameter: \(message)"

      case .OperationFailed(let message, let err):
        if let error = err {
          return "Operation failed: \(message), error: \(error.localizedDescription)"
        } else {
          return "Operation failed: \(message)"
        }
      
      case .searchFailed(let message):
        return "Search failed: \(message)"
    }
  }

  var originalError: Error? {
    switch self {
      case .InitializationError(let error): error
      case .OperationFailed(_, let error): error
      default: nil
    }
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
      case .searchFailed: 500
    }
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
      case .searchFailed:
        return "Unable to perform search."
    }
  }
}
