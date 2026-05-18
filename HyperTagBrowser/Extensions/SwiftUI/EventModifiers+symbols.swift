// created on 11/8/24 by robinsr

import SwiftUI


extension EventModifiers: @retroactive CaseIterable {
  public static var allCases: [EventModifiers] {
    return [.command, .control, .option, .shift, .capsLock]
  }
}


protocol ModUtilities {
  static func fromSymbol(_ symbol: String) -> Self
  var symbolName: String { get }
  var asCharacters: Character { get }
  var count: Int { get }
}



extension EventModifiers {
  
  init(modifierFlags: NSEvent.ModifierFlags) {
    var modifiers: EventModifiers = []
    
    if modifierFlags.contains(.shift) {
      modifiers.insert(.shift)
    }
    if modifierFlags.contains(.option) {
      modifiers.insert(.option)
    }
    if modifierFlags.contains(.control) {
      modifiers.insert(.control)
    }
    if modifierFlags.contains(.command) {
      modifiers.insert(.command)
    }
    if modifierFlags.contains(.capsLock) {
      modifiers.insert(.capsLock)
    }
    
    self = modifiers
  }
  
  init(string expr: String) {
    var modifiers: EventModifiers = []
    let chars = expr.split(separator: "")
    
    if chars.contains("⌘") { modifiers.insert(.command) }
    if chars.contains("⌃") { modifiers.insert(.control) }
    if chars.contains("⌥") { modifiers.insert(.option) }
    if chars.contains("⇧") { modifiers.insert(.shift) }
    
    self = modifiers
  }
  
  var modifierFlags: NSEvent.ModifierFlags {
#if os(macOS)
    var flags: NSEvent.ModifierFlags = []
    if contains(.capsLock) { flags.insert(.capsLock) }
    if contains(.control) { flags.insert(.control) }
    if contains(.option) { flags.insert(.option) }
    if contains(.command) { flags.insert(.command) }
    if contains(.shift) { flags.insert(.shift) }
    return flags
#else
    return []
#endif
  }
  
  static func fromSymbol(_ str: String) -> Self? {
    switch str {
    case "⌘": return .command
    case "⌃": return .control
    case "⌥": return .option
    case "⇧": return .shift
    default: return nil
    }
  }
  
  /**
   * SF Symbol name representing corresponding to this ModifierFlags (if length of 1)
   */
  var sfSymbolName: String {
    if self.count != 1 { return "questionmark" }
    
    switch self {
    case .command: return "command"
    case .control: return "control"
    case .option: return "option"
    case .shift: return "shift"
    case .capsLock: return "capslock"
    default: return "questionmark"
    }
  }
  
  /**
   * Returns the modifier's unicode glyph equivalent as a single-entry string (eg, "⌘", "⌃", etc)
   */
  var asSymbol: String {
    if self.count != 1 { return "?" }
    
    switch self {
    case .command: return "⌘"
    case .control: return "⌃"
    case .option: return "⌥"
    case .shift: return "⇧"
    case .capsLock: return "⇪"
    default: return ""
    }
  }
  
  /**
   * Returns an array of SF Symbol names representing the modifier keys contained in
   * this option set
   */
  var symbolNames: [String] {
    Self.allCases.filter(self.contains).map(\.sfSymbolName)
  }
  
  /**
   * Returns an array of single-character strings, each containing a unicode glpyh
   * representing one of the modifier keys contained in this option set
   */
  var asSymbols: [String] {
    Self.allCases.filter(self.contains).map(\.asSymbol)
  }
  
  var string: String {
    self.asSymbols.joined(separator: "")
  }
  
  var count: Int {
    var included = 0
    
    for mod in Self.allCases {
      if self.contains(mod) {
        included += 1
      }
    }
    
    return included
  }
  
  func contains(only mods: EventModifiers) -> Bool {
    if mods.count != 1 { return false }
    
    return self.contains(mods)
  }
  
  func equivalent(to mods: EventModifiers) -> Bool {
    for mod in Self.allCases {
      if self.contains(mod) != mods.contains(mod) {
        return false
      }
    }
    
    return true
  }
}


extension EventModifiers: ModKeyStatusReportable {

  func status(_ mod: NSEvent.ModifierFlags) -> KeyStatus {
    .fromBool(isPressed(mod))
  }

  func isPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    self.modifierFlags.isPressed(mod)
  }
  
  func isPressed(_ mod: NSEvent.ModifierFlags, with keyset: KeyCombinations) -> Bool {
    self.modifierFlags.isPressed(mod, with: keyset)
  }
  
  func isPressed(_ keyset: KeyCombinations) -> Bool {
    self.modifierFlags.isPressed(keyset)
  }
  
  func exclusivePressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    self.modifierFlags.exclusivePressed(mod)
  }
  
  func notPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    self.modifierFlags.notPressed(mod)
  }
}
