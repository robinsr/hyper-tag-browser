// created on 10/26/26 by robinsr

import Foundation

/// Turns SQL text into a stable key so the same statement shape aggregates together.
enum SQLNormalizer {

  /// Collapses whitespace and merges parenthesized placeholder lists, so
  /// `IN (?, ?, ?)` and `IN (?)` both become `IN (?…)`. Expects `Statement.sql` (placeholders),
  /// never `expandedSQL` (literal values).
  static func normalize(_ sql: String) -> String {
    let collapsed = sql.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    return collapsed.replacing(/\(\s*\?(?:\s*,\s*\?)*\s*\)/, with: "(?…)")
  }

  static func kind(of sql: String) -> String {
    let keyword = sql.prefix { !$0.isWhitespace }.lowercased()

    switch keyword {
      case "select", "with": return "select"
      case "insert", "replace": return "insert"
      case "update": return "update"
      case "delete": return "delete"
      case "begin": return "begin"
      case "commit": return "commit"
      default: return "other"
    }
  }

  /// FNV-1a 64-bit, as 16 lowercase hex characters. Stable across launches and platforms,
  /// unlike `hashValue`.
  static func fnv1a64(_ text: String) -> String {
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325

    for byte in text.utf8 {
      hash ^= UInt64(byte)
      hash = hash &* 0x0000_0100_0000_01b3
    }

    return String(format: "%016llx", hash)
  }

  static func info(for sql: String) -> SQLStatementInfo {
    let normalized = normalize(sql)
    return SQLStatementInfo(
      hash: fnv1a64(normalized), kind: kind(of: normalized), normalizedSQL: normalized)
  }
}
