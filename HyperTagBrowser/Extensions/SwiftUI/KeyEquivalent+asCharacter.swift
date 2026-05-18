// created on 11/8/24 by robinsr

import SwiftUI

extension KeyEquivalent {
  
  /**
   * Returns the key's unicode glyph equivalent as a single-entry string
   */
  var asSymbol: String {
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
  
  var name: String {
    switch self {
    case .delete: return "delete"
    case .escape: return "escape"
    case .tab: return "tab"
    case .space: return "space"
    case .return: return "return"
    case .rightArrow: return "rightArrow"
    case .leftArrow: return "leftArrow"
    case .downArrow: return "downArrow"
    case .upArrow: return "upArrow"
    case .pageDown: return "pageDown"
    case .pageUp: return "pageUp"
    default: return self.character.uppercased()
    }
  }
  
  var keyName: String {
    return "Key\(name.uppercased())"
  }
  
  var shiftCharacter: String {
    switch self.character {
    case ",": return "<"
    case ".": return ">"
    default: return self.asSymbol
    }
  }
  
  var asText: Text {
    return Text(self.asSymbol).monospaced()
  }
  
  var sfSymbolName: String {
    // For numeric keys, return "1.square", "2.square", etc
    if KeyEquivalent.numeric.contains(self) {
      return "\(self).square"
    }
    
    // For alpha keys, return "a.square", "b.square", etc
    if KeyEquivalent.alphabet.contains(self) {
      return "\(self.asSymbol.lowercased()).square"
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
    appendInterpolation(key.keyName)
  }
}
