// created on 4/8/25 by robinsr

import Foundation

extension DateFormatter {
  static let iso8601 = ISO8601DateFormatter()
  
  
  /**
   * Formats a date to the `.short` style, eg "5/14/25".
   */
  static var short: DateFormatter {
    withDateStyle(.short)
  }
  
  /**
   * Formats a date to the `.medium` style, eg "May 14, 2025".
   */
  static var medium: DateFormatter {
    withDateStyle(.medium)
  }
  
  /**
   * Formats a date to the `.long` style, eg "May 14, 2025".
   * This is the same as `.medium` in the US locale.
   */
  static var long: DateFormatter {
    withDateStyle(.long)
  }
  
  static var filename: DateFormatter {
    let fmt = DateFormatter()
    
    fmt.dateFormat = "yyyyMMddHHmmss"
    fmt.locale = Locale(identifier: "en_US")
    
    return fmt
  }
  
  static func withDateStyle(_ style: DateFormatter.Style) -> DateFormatter {
    let fmt = DateFormatter()
    
    fmt.dateStyle = style
    fmt.timeStyle = .none
    fmt.locale = Locale(identifier: "en_US")
    
    return fmt
  }
  
  
  /**
   * A ISO date formatter with the format "yyyy-MM-dd".
   *
   * Usage:
   *
   * ```swift
   * let date = Date()
   * let dateString = DateFormatter.isoDate.string(from: date)
   * // print(dateString) // "2025-05-14"
   * ```
   */
  static var isoDate: ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    
    formatter.timeZone = TimeZone.current
    formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate]
    
    return formatter
  }
  
  static var isoDateTime: ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    
    formatter.timeZone = TimeZone.current
    formatter.formatOptions = [
      .withFullDate, .withDashSeparatorInDate, .withTime, .withSpaceBetweenDateAndTime, .withColonSeparatorInTime
    ]
    
    return formatter
  }
}
