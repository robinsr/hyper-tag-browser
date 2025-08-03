// created on 11/8/24 by robinsr

import SwiftUI


extension EventModifiers {
  var allCases: [EventModifiers] {
    return [.command, .control, .option, .shift, .capsLock]
  }
}



extension EventModifiers {
  
  static func fromSymbol(_ str: String) -> Self? {
    switch str {
    case "⌘": return .command
    case "⌃": return .control
    case "⌥": return .option
    case "⇧": return .shift
    default: return nil
    }
  }
  
  var symbolName: String {
    switch self {
    case .command: return "command"
    case .control: return "control"
    case .option: return "option"
    case .shift: return "shift"
    case .capsLock: return "capslock"
    default: return "questionmark"
    }
  }
  
  var asCharacter: String {
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
   * Returns a set of SF Symbol names representing the modifier keys contained in
   * this option set
   */
  var symbolNames: [String] {
    let allMods: [EventModifiers] = [.command, .control, .option, .shift]
    
    return allMods
      .filter { self.contains($0) }
      .map { $0.symbolName }
  }
  
  /**
   * Returns a set of single-character strings, each containing a unicode glpyh
   * representing one of the modifier keys contained in this option set
   */
  var asCharacters: [String] {
    let allMods: [EventModifiers] = [.command, .control, .option, .shift]
    
    return allMods
      .filter { self.contains($0) }
      .map { $0.asCharacter }
  }
  
  var string: String {
    self.asCharacters.joined(separator: "")
  }
  
  var count: Int {
    var included = 0
    
    for mod in allCases {
      if self.contains(mod) {
        included += 1
      }
    }
    
    return included
  }
  
  var none: Bool {
    count == 0
  }
  
  func contains(only mods: EventModifiers) -> Bool {
    if mods.count != 1 { return false }
    
    return self.contains(mods)
  }
  
  func equivalent(to mods: EventModifiers) -> Bool {
    let allMods: [EventModifiers] = [.command, .control, .option, .shift]
    
    for mod in allMods {
      if self.contains(mod) != mods.contains(mod) {
        return false
      }
    }
    
    return true
  }
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
}

extension EventModifiers: KeyModifierList {
  func isPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    contains(EventModifiers(modifierFlags: mod))
  }
  
  func notPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    !isPressed(mod)
  }
}
