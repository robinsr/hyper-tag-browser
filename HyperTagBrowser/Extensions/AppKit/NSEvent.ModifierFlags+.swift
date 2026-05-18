// created on 11/1/25 by robinsr

import AppKit


extension NSEvent.ModifierFlags: @retroactive CaseIterable {
  public static var allCases: [NSEvent.ModifierFlags] {
    return [.command, .control, .option, .shift, .capsLock]
  }
}

extension NSEvent.ModifierFlags {
  
  /**
   * A set of single-member `NSEvent.ModifierFlags`, together the equivalent of this `NSEvent.Modifier`
   */
  var keys: [Self] {
    Self.allCases.filter(self.contains)
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
  
  var symbolNames: [String] {
    Self.allCases.filter(self.contains).map(\.symbolName)
  }
  
  var asCharacters: [String] {
    Self.allCases.filter(self.contains).map(\.asCharacter)
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
  
  var none: Bool {
    count == 0
  }
}


extension NSEvent.ModifierFlags: @retroactive CustomStringConvertible {
  public var description: String {
    self.symbolNames.joined(separator: ",")
  }
}

extension NSEvent.ModifierFlags: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "NSEvent.ModifierFlags([\(self.symbolNames.joined(separator: ","))])"
  }
}


extension NSEvent.ModifierFlags: ModKeyStatusReportable {
  func status(_ mod: NSEvent.ModifierFlags) -> KeyStatus {
    .fromBool(self.contains(mod))
  }
  
  func isPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    let result = self.contains(mod)
//    print("ModifierFlags.isPressed(mod:\(mod)) = \(result)")
    return result
  }
  
  func isPressed(_ mod: NSEvent.ModifierFlags, with keyset: KeyCombinations) -> Bool {
    let result = isPressed(mod) && isPressed(keyset)
//    print("ModifierFlags.isPressed(mod:\(mod), keyset:\(keyset)) = \(result)")
    return result
  }
  
  func isPressed(_ keyset: KeyCombinations) -> Bool {
    var result = false
    
    switch keyset {
    case .either(let mods):
      result = mods.keys.map { self.exclusivePressed($0) }.filter { $0 }.count > 0
    case .any(let mods):
      result = mods.keys.first { self.isPressed($0) } != nil
    case .all(let mods):
      result = mods.keys.allSatisfy { self.isPressed($0) }
    case .none(let mods):
      result = mods.keys.allSatisfy { self.notPressed($0) }
    }
    
//    print("ModifierFlags.isPressed(keyset:\(keyset)) = \(result)")
    
    return result
  }
  
  func exclusivePressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    let result = self.contains(mod) && self.count == 1
//    print("ModifierFlags.exclusivePressed(mod:\(mod)) = \(result)")
    return result
  }
  
  func notPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    let result = !isPressed(mod)
//    print("ModifierFlags.notPressed(mod:\(mod)) = \(result)")
    return result
  }
}

