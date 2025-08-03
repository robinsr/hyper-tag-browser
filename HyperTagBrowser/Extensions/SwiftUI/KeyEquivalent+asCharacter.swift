// created on 11/8/24 by robinsr

import SwiftUI

extension KeyEquivalent {
  
  /**
    Returns a single-character string containing the key's unicode glyph equivalent
   */
  var asCharacter: String {
    switch self {
    case .delete: return "⌫"
    case .escape: return "⎋"
    case .tab: return "⇥"
    case .space: return "␣"
    case .return: return "↵"
    case .rightArrow: return "→"
    case .leftArrow: return "←"
    case .downArrow: return "↓"
    case .upArrow: return "↑"
    case .pageDown: return "⇟"
    case .pageUp: return "⇞"
    default: return self.character.uppercased()
    }
  }
  
  var shiftCharacter: String {
    switch self.character {
    case ",": return "<"
    case ".": return ">"
    default: return self.asCharacter
    }
  }
  
  var asText: Text {
    return Text(self.asCharacter).monospaced()
  }
  
  var symbolName: String {
    if KeyEquivalent.numeric.contains(self) {
      return "\(self).square"
    }
    
    if KeyEquivalent.alphabet.contains(self) {
      return "\(self.asCharacter.lowercased()).square"
    }
    
    switch self {
    case .delete: return "delete.left"
    case .escape: return "escape"
    case .tab: return "arrow.right.to.line.compact"
    case .space: return "space"
    case .return: return "return"
    case .rightArrow: return "arrow.right"
    case .leftArrow: return "arrow.left"
    case .downArrow: return "arrow.down"
    case .upArrow: return "arrow.up"
    case .pageDown: return "arrow.down.to.line"
    case .pageUp: return "arrow.up.to.line"
    default: return "questionmark"
    }
  }
  
  
  /**
   A collection of KeyEquivalent values for the numeric keys 0-9
   */
  static var numeric: [KeyEquivalent] {
    "1234567890".split(separator: "")
      .map { Character($0.unicodeScalars.first!) }
      .map { .init(unicodeScalarLiteral: $0) }
  }
  
  static var alphabet: [KeyEquivalent] {
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".split(separator: "")
      .map { Character($0.unicodeScalars.first!) }
      .map { .init(unicodeScalarLiteral: $0) }
  }
  
  static var punctuation: [KeyEquivalent] {
    ",./;'[]\\`".split(separator: "")
      .map { Character($0.unicodeScalars.first!) }
      .map { .init(unicodeScalarLiteral: $0) }
  }
  
  static var special: [KeyEquivalent] {
    [
      .delete, .escape, .tab, .space, .return,
      .rightArrow, .leftArrow, .downArrow, .upArrow,
      .pageDown, .pageUp
    ]
  }
}

extension String.StringInterpolation {
  mutating func appendInterpolation(key: KeyEquivalent) {
    appendInterpolation(key.asCharacter)
  }
}
