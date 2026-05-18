// created on 12/23/25 by robinsr

import Foundation


/**
 * Provides definitions for the Spotlight **Value Comparison Modifiers**
 *
 * See [File Metadata Query Expression Syntax](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html)
 *
 * - `c` - Performs a case-insensitive search.
 * - `d` - Performs a search that ignores diacritical marks.
 * - `w` - Matches on word boundaries. This modifier treats transitions from lowercase to uppercase as word boundaries.
 * - `t` - Performs a search on a tokenized value. For example, a search field can contain tokenized values.
 * - `*` - Performs a wildcard search. Match a substring at the beginning, end, or middle.
 * - `\` - Don’t interpret the character that follows. Use this to include special characters. Examples include \’ and \”.
 */
enum SearchTermModifier: String, Sendable {
  
    /// `c` - Performs a case-insensitive search.
  case caseInsensitive
  
    /// `d` - Performs a search that ignores diacritical marks.
  case diacriticInsensitive
  
    /// `w` - Matches on word boundaries. This modifier treats transitions from lowercase to uppercase as word boundaries.
  case wordBoundary
  
    /// `t` - Performs a search on a tokenized value. For example, a search field can contain tokenized values.
  case tokenized
  
    /// `*` - Performs a wildcard search. Match a substring at the beginning, end, or middle.
  case wildcard
  
    /// `\` - Don’t interpret the character that follows. Use this to include special characters. Examples include \’ and \”.
  case escaped
  
  var rawValue: String {
    switch self {
    case .caseInsensitive: return "c"
    case .diacriticInsensitive: return "d"
    case .wordBoundary: return "w"
    case .tokenized: return "t"
    case .wildcard: return "*"
    case .escaped: return "\\"
    }
  }
}

extension Set where Element == SearchTermModifier {
  var mdQueryModifiers: String {
    self.map(\.rawValue).joined(separator: "")
  }
}
