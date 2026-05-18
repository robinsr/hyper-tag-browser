// created on 4/18/25 by robinsr

import Factory
import Foundation
import OSLog
import SwiftUI


/**
 * A categorized message intended for UI display.
 *
 * ```swift
 * send(.init("Successfully renamed file", category: .success))
 * ```
 *
 * AppMessage is immutable and therefore thread-safe, so can conform to Sendabl
 */
struct AppMessage: Sendable, Equatable, Identifiable, Encodable {
  let id = UUID()
  let timestamp: Date = .now

  let message: String
  var details: String = "none"
  var level: Level = .info
  
  enum CodingKeys: String, CodingKey {
    case id, timestamp, message, level
  }
  
  init(_ message: String) {
    self.message = message
  }

  init(_ message: String, _ level: Level) {
    self.message = message
    self.level = level
  }
  
  init(_ message: String, _ level: Level, details: String) {
    self.message = message
    self.level = level
    self.details = details
  }
  
  init(_ message: String, _ level: Level = .error, _ error: Error) {
    self.message = message
    self.level = level
    self.details = error.localizedDescription
  }
  
  init(_ message: String, _ level: Level = .error, _ error: ErrorMsg) {
    self.message = message
    self.level = level
    self.details = error.errorDescription ?? error.errorDetails ?? ""
  }
  
  init(_ message: String, _ level: Level = .success, arguments: CVarArg...) {
    self.message = String(format: message, arguments)
    self.level = level
  }
  
  @available(*, deprecated, renamed: "message", message: "Use `message` instead")
  var body: String {
    self.message
  }
  
  func newerThan(moment: Date) -> Bool {
    timestamp >= moment
  }
  
  var isTransient: Bool {
    level.oneOf(.success, .info, .warning)
  }
  
  var isPersistent: Bool {
    level.oneOf(.error, .restart)
  }
  
  static func ok(_ msg: String) -> AppMessage {
    AppMessage(msg, .success)
  }
  
  static func info(_ msg: String) -> AppMessage {
    AppMessage(msg, .info)
  }
  
  static func warning(_ msg: String) -> AppMessage {
    AppMessage(msg, .warning)
  }
  
  static func error(_ msg: String) -> AppMessage {
    AppMessage(msg, .warning)
  }
  
  static func error(_ msg: String, _ error: Error) -> AppMessage {
    AppMessage(msg, .warning, details: error.legibleLocalizedDescription)
  }
  
  static func error(_ err: ErrorMsg) -> AppMessage {
    AppMessage(err.message, .warning, err)
  }
  
  static func fatal(_ msg: String) -> AppMessage {
    AppMessage(msg, .error)
  }
  
  static func fatal(_ msg: String, _ error: Error) -> AppMessage {
    AppMessage(msg, .error, details: error.legibleLocalizedDescription)
  }
  
  static func fatal(_ err: ErrorMsg) -> AppMessage {
    AppMessage(err.message, .error, err)
  }
}


extension AppMessage {
  
  /**
   * Analogous to log level
   */
  enum Level: String, CaseIterable, Identifiable, Comparable, Codable {
    case success, info, warning, error, restart

    var id: Self { self }
    
    var title: String { rawValue.capitalized }
    
    var loglevel: Logger.Level {
      switch self {
      case .success: return .success
      case .info: return .info
      case .warning: return .warning
      case .error: return .error
      case .restart: return .info
      }
    }
    
    var alertIcon: SymbolIcon {
      switch self {
      case .success: return .itemChecked
      case .info: return .info
      case .restart: return .info
      case .warning: return .warning
      case .error: return .error
      }
    }
    
    var alertColor: Color {
      let theme = Container.shared.themeProvider()
      
      switch self {
      case .success: return theme.success
      case .info: return theme.info
      case .restart: return theme.info
      case .warning: return theme.danger
      case .error: return theme.error
      }
    }
    
    static func < (lhs: AppMessage.Level, rhs: AppMessage.Level) -> Bool {
      let levelOrder : [AppMessage.Level] = [.success, .info, .warning, .error, .restart]
      
      let lhsInd = levelOrder.firstIndex(of: lhs)!
      let rhsInd = levelOrder.firstIndex(of: rhs)!
      
      return lhsInd < rhsInd
    }
  }
}
