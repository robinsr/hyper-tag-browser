// Created on 9/15/24 by robinsr

import CustomDump
import OSLog

public struct CustomLogger : @unchecked Sendable {
  
  typealias Level = Logger.Level
  typealias Event = Logger.Event
  
  var level: Level
  let subsystem: String
  let category: String
  let oslogger: os.Logger
  
  init(subsystem: String, category: String, level: Level = .info) {
    self.subsystem = subsystem
    self.category = category
    self.level = level
    self.oslogger = Logger(subsystem: subsystem, category: category)
  }
  
  init(_ category: String, level: Level = .info) {
    self.init(subsystem: Bundle.main.bundleIdentifier!, category: category, level: level)
  }
  
  func sublogger(_ category: String, level: Level? = nil) -> CustomLogger {
    let _category = "\(self.category).\(category)"
    let _level = level ?? self.level
    
    return CustomLogger(subsystem: self.subsystem, category: _category, level: _level)
  }
  
  /// Emits a log message with the specified level and `String` message.
  func emit(
    _ level: Level,
    _ msg: String,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    if level > self.level { return }
    
    let caller = oslogger.callerInfo(dfile, dline, dfunc)
    let evt = Event(caller: caller, level: level, message: msg, attributes: [:])

    switch level {
    case .critical:
      oslogger.critical("\(evt.logMessage)")
    case .error:
      oslogger.error("\(evt.logMessage)")
    case .warning:
      oslogger.warning("\(evt.logMessage)")
    case .info, .success, .stats:
      oslogger.info("\(evt.logMessage)")
    case .debug:
      oslogger.debug("\(evt.logMessage)")
    case .trace:
      oslogger.trace("\(evt.logMessage)")
    default:
      if let type = level.config.logType {
        oslogger.log(level: type, "\(evt.logMessage)")
      }
    }
  }

  /// Emits a log message with the specified level and `ErrorMsg` object.
  func emit(
    _ level: Logger.Level,
    _ err: ErrorMsg,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    var printout = ""
    print(err, to: &printout)
    emit(level, printout, dfile: dfile, dline: dline, dfunc: dfunc)
  }

  /// Emits a log message with the specified level and `Error` object.
  func emit(
    _ level: Logger.Level,
    _ error: any Error,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    var printout = ""
    print(error, to: &printout)
    emit(level, printout, dfile: dfile, dline: dline, dfunc: dfunc)
  }
  
  func debug(
    _ msg: String,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    self.emit(.debug, msg, dfile: dfile, dline: dline, dfunc: dfunc)
  }
  
  func info(
    _ msg: String,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    self.emit(.info, msg, dfile: dfile, dline: dline, dfunc: dfunc)
  }
  
  func warning(
    _ msg: String,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    self.emit(.warning, msg, dfile: dfile, dline: dline, dfunc: dfunc)
  }
  
  func error(
    _ msg: String,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    self.emit(.error, msg, dfile: dfile, dline: dline, dfunc: dfunc)
  }
  
  func error(
    _ err: ErrorMsg,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    self.emit(.error, err, dfile: dfile, dline: dline, dfunc: dfunc)
  }

  /// Dumps a data structure to the log via `CustomDump` library.
  func dump(
    _ data: Any,
    label: String,
    dfile: String = #file,
    dline: Int = #line,
    dfunc: String = #function
  ) {
    var prefixMsg = Level.trace.description.padding(toLength: 12, withPad: " ", startingAt: 0)
    let caller = oslogger.callerInfo(dfile, dline, dfunc)

    prefixMsg += " (\(caller.description)):"

    let prefix = prefixMsg.padding(
      toLength: max(prefixMsg.count, 100),
      withPad: ".",
      startingAt: 0
    )

    var output = ""
    customDump(data, to: &output, name: label)
    oslogger.trace("\(prefix) - \(output)")
  }
  
  mutating func level(_ level: Level) -> Self {
    self.level = level
    return self
  }
}

extension os.Logger {
  // static let shared = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Shared")

  /// Creates a new logger with the given category. General purpose entry-point for log event producers.
//  static func newLog(label category: String) -> os.Logger {
//    Logger(subsystem: Bundle.main.bundleIdentifier!, category: category)
//  }
  static func newLog(label category: String) -> CustomLogger {
    CustomLogger(subsystem: Bundle.main.bundleIdentifier!, category: category)
  }

  /// Emits a log message with the specified level and `String` message.
//  func emit(
//    _ level: Level,
//    _ msg: String,
//    dfile: String = #file,
//    dline: Int = #line,
//    dfunc: String = #function
//  ) {
//
//    let caller = callerInfo(dfile, dline, dfunc)
//    let evt = Event(caller: caller, level: level, message: msg, attributes: [:])
//
//    switch level {
//      case .critical: critical("\(evt.logMessage)")
//      case .error: error("\(evt.logMessage)")
//      case .warning: warning("\(evt.logMessage)")
//      case .info, .success, .stats: info("\(evt.logMessage)")
//      case .debug: debug("\(evt.logMessage)")
//      case .trace: trace("\(evt.logMessage)")
//      default:
//        if let type = level.config.logType {
//          log(level: type, "\(evt.logMessage)")
//        }
//    }
//  }

  /// Emits a log message with the specified level and `ErrorMsg` object.
//  func emit(
//    _ level: Level,
//    _ err: ErrorMsg,
//    dfile: String = #file,
//    dline: Int = #line,
//    dfunc: String = #function
//  ) {
//    var printout = ""
//    print(err, to: &printout)
//    emit(level, printout, dfile: dfile, dline: dline, dfunc: dfunc)
//  }

  /// Emits a log message with the specified level and `Error` object.
//  func emit(
//    _ level: Level,
//    _ error: any Error,
//    dfile: String = #file,
//    dline: Int = #line,
//    dfunc: String = #function
//  ) {
//    var printout = ""
//    print(error, to: &printout)
//    emit(level, printout, dfile: dfile, dline: dline, dfunc: dfunc)
//  }

  /// Dumps a data structure to the log via `CustomDump` library.
//  func dump(
//    _ data: Any,
//    label: String,
//    dfile: String = #file,
//    dline: Int = #line,
//    dfunc: String = #function
//  ) {
//    var prefixMsg = Level.trace.description.padding(toLength: 12, withPad: " ", startingAt: 0)
//    let caller = callerInfo(dfile, dline, dfunc)
//
//    prefixMsg += " (\(caller.description)):"
//
//    let prefix = prefixMsg.padding(
//      toLength: max(prefixMsg.count, 100),
//      withPad: ".",
//      startingAt: 0
//    )
//
//    var output = ""
//    customDump(data, to: &output, name: label)
//    trace("\(prefix) - \(output)")
//  }
}
