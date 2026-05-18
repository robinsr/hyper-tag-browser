// created on 11/24/25 by robinsr

import OSLog


extension Logger {
  
  enum Level: String, CaseIterable, CustomStringConvertible, RawRepresentable, Comparable {
    case critical
    case error
    case warning
    case success
    case action
    case info
    case debug
    case trace
    case stats
    case off
    
    init?(rawValue: String) {
      guard let this = Self.allCases.first(where: { $0.rawValue == rawValue }) else {
        return nil
      }
      
      self = this
    }
    
    static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
      lhs.numeral < rhs.numeral
    }

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
        case .critical: LogLevelConfig(.fault, icon: "🔴")
        case .error: LogLevelConfig(.fault, icon: "🟠")
        case .warning: LogLevelConfig(.error, icon: "🟡")
        case .success: LogLevelConfig(.default, icon: "🟢")
        case .action: LogLevelConfig(.info, icon: "🟣")
        case .info: LogLevelConfig(.info, icon: "🪵")
        case .debug: LogLevelConfig(.debug, icon: "🔷")
        case .trace: LogLevelConfig(.debug, icon: "⚪️")
        case .stats: LogLevelConfig(.default, icon: "📊", options: [.omitsCallerInfo, .omitsLevelPrefix])
        default: LogLevelConfig(nil, icon: "❓")
      }
    }
    
    var numeral: Int {
      switch self {
      case .stats: -1
      case .off: 0
      case .critical: 1
      case .error: 2
      case .warning: 3
      case .info, .success, .action: 4
      case .debug: 7
      case .trace: 8
      }
    }
    
    var label: String {
      switch self {
      case .critical: "Critical"
      case .error: "Error"
      case .warning: "Warning"
      case .success: "Success"
      case .action: "Action"
      case .info: "Info"
      case .debug: "Debug"
      case .trace: "Trace"
      case .stats: "Stats"
      case .off: "off"
      }
    }

    var linePrefix: String {
      switch self {
      case .off: ""
      default: "\(config.icon) \(label):".padding(toLength: 12, withPad: " ", startingAt: 0)
      }
    }

    var description: String {
      switch self {
      case .off: "Logging is off"
      default: linePrefix
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
}
