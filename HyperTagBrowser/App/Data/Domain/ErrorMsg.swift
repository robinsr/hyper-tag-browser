// created on 9/19/24 by robinsr

import Foundation


struct ErrorMsg: CustomStringConvertible, CustomDebugStringConvertible {
  var message: String = "No error message given"
  var errorDescription: String? = nil
  var errorDetails: String? = nil
  
  var error: Error? = nil
  
  init(_ message: String) {
    self.message = message
  }
  
  init(_ error: any Error) {
    self.message = error.legibleLocalizedDescription
    self.errorDescription = error.legibleLocalizedDescription
    
    var errorPrintout = ""
    print(error, to: &errorPrintout)
    
    self.errorDetails = errorPrintout
  }
  
  init(_ message: String, _ error: any Error) {
    self.message = message
    self.errorDescription = error.legibleLocalizedDescription
    
    var errorPrintout = ""
    print(error, to: &errorPrintout)
    
    self.errorDetails = errorPrintout
  }
  
  var description: String {
    """
    ErrorMsg(
      message: "\(message)"
      errorDescription: \(errorDescription ?? "none")
      errorDetails: \(errorDetails ?? "none")
    )
    """
  }
  
  var debugDescription: String {
    JSONEncoder.pretty(self)
  }
  
  enum CodingKeys: String, CodingKey {
    case message
    case errorDescription
    case errorDetails
  }
  
  
  /**
   * Creates an ErrorMsg instance with a message and an error.
   *
   * Usage:
   *
   * ```swift
   * do {
   *   //...
   * } catch {
   *  send(.raised("Failed to perform operation", error))
   * }
   */
  static func raised(_ message: String, _ error: any Error) -> Self {
    .init(message, error)
  }
  
  
  /**
   * Creates an ErrorMsg instance for any Error modeled in ``ModeledError``.
   *
   * Usage:
   *
   * ```swift
   * do {
   *   //...
   * } catch {
   *  send(.modeled(.failedToDoOperation(error)))
   *  // or
   *  send(.modeled(.networkError("whatever error message here")))
   * }
   */
  static func modeled(_ error: ModeledError) -> Self {
    // Assuming ModeledError has a message property
    .init(error.message)
  }
}
