// created on 11/24/25 by robinsr

import OSLog


extension os.Logger {
  
  /**
   * A container for a log event, combining the caller information, log level, message, and optional attributes.
   */
  struct Event {
    let caller: CodeLocation
    let level: os.Logger.Level
    let message: String
    var attributes: [String:String] = [:]

    var logMessage: String {
      let prefixes: [String?] = [
        level.logsPrefix ? level.description : nil,
        level.logsCaller ? caller.label : nil,
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
