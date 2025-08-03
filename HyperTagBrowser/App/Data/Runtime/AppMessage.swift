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
  let level: Level
  let rawValue: String
  var details: String = ""

  init(_ message: String, _ level: Level = .error, details: String = "") {
    self.rawValue = message
    self.level = level
    self.details = details
  }
  
  init(_ message: String, _ level: Level = .success, arguments: CVarArg...) {
    self.rawValue = String(format: message, arguments)
    self.level = level
  }
  
  var body: String { rawValue }

  
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
    AppMessage(err.message, .warning, details: err.details)
  }
  
  static func fatal(_ msg: String) -> AppMessage {
    AppMessage(msg, .error)
  }
  
  static func fatal(_ msg: String, _ error: Error) -> AppMessage {
    AppMessage(msg, .error, details: error.legibleLocalizedDescription)
  }
  
  static func fatal(_ err: ErrorMsg) -> AppMessage {
    AppMessage(err.message, .error, details: err.details)
  }
}


extension AppMessage {
  
  /**
   * Analogous to log level
   */
  enum Level: String, CaseIterable, Identifiable, Codable {
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
  }
}
