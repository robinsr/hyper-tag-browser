// created on 9/19/24 by robinsr

import Foundation


struct ErrorMsg: Codable, CustomStringConvertible, CustomDebugStringConvertible {
  var message: String = "No error message given"
  var details: String = ""
  
  init(_ message: String) {
    self.message = message
  }
  
  init(_ error: any Error) {
    self.message = error.legibleLocalizedDescription
    
    print(error, to: &self.details)
  }
  
  init(_ message: String, _ error: any Error) {
    self.message = "\(message): \(error.legibleLocalizedDescription)"
    
    print(error, to: &self.details)
  }
  
  var description: String {
    "\(message) \(details)"
  }
  
  var debugDescription: String {
    "\(message) \(details)"
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
