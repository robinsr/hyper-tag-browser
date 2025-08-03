// Created on 9/15/24 by robinsr

import CustomDump
import OSLog
import OpenTelemetryApi
import SwiftUI
import System

extension os.Logger {

  static let shared = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Shared")

  /**
   * Creates a new logger with the given category. General purpose entry-point for log event producers.
   */
  static func newLog(label category: String) -> os.Logger {
    Logger(subsystem: Bundle.main.bundleIdentifier!, category: category)
  }

  private func callerInfo(_ file: String, _ line: Int, _ function: String) -> Caller {
    Caller(filepath: FilePath(file), fnName: function, line: line)
  }

  /**
   * Emits a log message with the specified level and `String` message.
   *
   * - Parameters:
   *    - level: The log level at which to emit the message.
   *    - msg: The message to log.
   */
  func emit(
    _ level: Level, _ msg: String, dfile: String = #file, dline: Int = #line,
    dfunc: String = #function
  ) {

    let evt = Event(
      caller: callerInfo(dfile, dline, dfunc),
      level: level,
      message: msg,
      attributes: [:]
    )

    switch level {
      case .critical:
        critical("\(evt.logMessage)")
      case .error:
        error("\(evt.logMessage)")
      case .warning:
        warning("\(evt.logMessage)")
      case .info, .success, .stats:
        info("\(evt.logMessage)")
      case .debug:
        debug("\(evt.logMessage)")
      case .trace:
        trace("\(evt.logMessage)")
      default:
        if let type = level.config.logType {
          log(level: type, "\(evt.logMessage)")
        }
    }
  }

  /**
   * Dumps a data structure to the log via `CustomDump` library.
   *
   * - Parameters:
   *   - data: The data structure to dump.
   *   - label: A label for the data structure, used in the log output.
   */
  func dump(
    _ data: Any, label: String, dfile: String = #file, dline: Int = #line, dfunc: String = #function
  ) {
    var prefixMsg = Level.trace.description.padding(toLength: 12, withPad: " ", startingAt: 0)
    let caller = callerInfo(dfile, dline, dfunc)

    prefixMsg += " (\(caller.description)):"

    let prefix = prefixMsg.padding(
      toLength: max(prefixMsg.count, 100),
      withPad: ".",
      startingAt: 0
    )

    var output = ""
    customDump(data, to: &output, name: label)
    trace("\(prefix) - \(output)")
  }

  /**
   * Emits a log message with the specified level and `ErrorMsg` object.
   *
   * - Parameters:
   *    - level: The log level at which to emit the error message.
   *    - err: The `ErrorMsg` object from which to extract the message.
   */
  func emit(
    _ level: Level, _ err: ErrorMsg, dfile: String = #file, dline: Int = #line,
    dfunc: String = #function
  ) {
    var printout = ""
    print(err, to: &printout)
    emit(level, printout, dfile: dfile, dline: dline, dfunc: dfunc)
  }

  /**
   * Emits a log message with the specified level and `Error` object.
   *
   * - Parameters:
   *    - level: The log level at which to emit the error message.
   *    - error: The `Error` from which to extract the message.
   */
  func emit(
    _ level: Level, _ error: any Error, dfile: String = #file, dline: Int = #line,
    dfunc: String = #function
  ) {
    var printout = ""
    print(error, to: &printout)
    emit(level, printout, dfile: dfile, dline: dline, dfunc: dfunc)
  }

  enum Level: String, CustomStringConvertible {
    case critical = "Critical"
    case error = "Error"
    case warning = "Warning"
    case success = "Success"
    case action = "Action"
    case info = "Info"
    case debug = "Debug"
    case trace = "Trace"
    case stats = "Stats"
    case off = "none"

    /**
     * Returns the noop log level. Useful for disabling specific log messages
     *
     * ```swift
     * logger.emit(.debug.off, "Re-enable this message when debugging is needed")
     * ```
     */
    var off: Self {
      return .off
    }

    /**
     * Defines the logging configuration for this log level, including the icon
     * os.Logger level equivalent, and any options
     */
    var config: LogLevelConfig {
      switch self {
        case .critical:
          LogLevelConfig(.fault, icon: "🔴")
        case .error:
          LogLevelConfig(.fault, icon: "🟠")
        case .warning:
          LogLevelConfig(.error, icon: "🟡")
        case .success:
          LogLevelConfig(.default, icon: "🟢")
        case .action:
          LogLevelConfig(.info, icon: "🟣")
        case .info:
          LogLevelConfig(.info, icon: "🪵")
        case .debug:
          LogLevelConfig(.debug, icon: "🔷")
        case .trace:
          LogLevelConfig(.debug, icon: "⚪️")
        case .stats:
          LogLevelConfig(.default, icon: "📊", options: [.omitsCallerInfo, .omitsLevelPrefix])
        default:
        LogLevelConfig(nil, icon: "❓")
      }
    }

    var linePrefix: String {
      "\(config.icon) \(rawValue):".padding(toLength: 12, withPad: " ", startingAt: 0)
    }

    var description: String {
      switch self {
        case .critical, .error, .warning, .success, .action, .info, .debug, .trace, .stats:
          return linePrefix
        case .off:
          return "Logging is off"
      }
    }

    var logsCaller: Bool {
      self.config.options.contains(.omitsCallerInfo) == false
    }

    var logsPrefix: Bool {
      self.config.options.contains(.omitsLevelPrefix) == false
    }

    var prefixLength: Int {
      for opt in config.options {
        if case .fixedPrefixWidth(let width) = opt {
          return width
        }
      }
      return 0
    }

    struct LogLevelConfig {
      let logType: OSLogType?
      let icon: String
      var options: [Options] = []

      init(_ level: OSLogType? = nil, icon: String = "", options: [Options] = [.fixedPrefixWidth(60)]) {
        self.logType = level
        self.icon = icon
        self.options = options
      }

      enum Options: Hashable, Equatable {
        case omitsLevelPrefix
        case omitsCallerInfo
        case fixedPrefixWidth(Int)
      }
    }


  }

  /**
   * A struct that contains information about the caller of a log message. Provides context for log messages, including
   * caller's file path, function name, and line number. Handles some formatting for display purposes.
   */
  struct Caller: CustomStringConvertible {
    let filepath: FilePath
    let fnName: String
    let line: Int

    var functionName: String {
      String(fnName.prefix(while: { $0 != "(" }))
    }

    var filename: String {
      filepath.baseName
    }

    var moduleName: String {
      filepath.stem ?? String(filepath.baseName.prefix(while: { $0 != "." }))
    }

    var description: String {
      "\(moduleName)#\(functionName):\(line)"
    }

    var debugDescription: String {
      """
      Caller(\(description.quoted)
        arg.filepath: \(filepath),
        arg.fnName: "\(fnName)",
        arg.line: \(line),
        moduleName: "\(moduleName)",
        filename: "\(filename)",
        workspace: \(Constants.workspaceFilepath.string)
      )
      """
    }
  }

  /**
   * A container for a log event, combining the caller information, log level, message, and optional attributes.
   */
  struct Event {
    let caller: os.Logger.Caller
    let level: os.Logger.Level
    let message: String
    var attributes: AttributeValueMap = [:]

    var logMessage: String {
      let prefixes: [String?] = [
        level.logsPrefix ? level.description : nil,
        level.logsCaller ? caller.description : nil,
      ]

      let prefix = prefixes.compactMap(\.?).joined(separator: " ")

      var msg = prefix

      if level.prefixLength > 0 {
        msg = prefix.padding(
          toLength: max(prefix.count, level.prefixLength),
          withPad: ".",
          startingAt: 0)
      }

      return msg.isEmpty ? message : "\(msg): \(message)"
    }
  }
}

extension View {

  /**
   * Experimental: Create a new logger for the view.
   *
   */
  // TODO: This is experimental, and may not work as expected. Determine if this is worth keeping.
  public static func newLogger(_ viewName: String = #filePath) -> os.Logger {
    return os.Logger.newLog(label: viewName)
  }
}
