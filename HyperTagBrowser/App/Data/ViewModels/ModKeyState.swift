// created on 11/12/24 by robinsr

import SwiftUI

protocol ModKeyStatusReportable {
  func status(_ mod: NSEvent.ModifierFlags) -> KeyStatus
  func isPressed(_ mod: NSEvent.ModifierFlags) -> Bool
  func isPressed(_ mod: NSEvent.ModifierFlags, with keyset: KeyCombinations) -> Bool
  func isPressed(_ keyset: KeyCombinations) -> Bool
  func exclusivePressed(_ mod: NSEvent.ModifierFlags) -> Bool
  func notPressed(_ mod: NSEvent.ModifierFlags) -> Bool
}

enum KeyCombinations {
  typealias Mods = NSEvent.ModifierFlags
  
  case either(Mods)
  case any(Mods)
  case all(Mods)
  case none(Mods)
  
  var mods: [Mods] {
    switch self {
    case .either(let mods): return mods.keys
    case .any(let mods): return mods.keys
    case .all(let mods): return mods.keys
    case .none(let mods): return mods.keys
    }
  }
}

extension KeyCombinations: CustomStringConvertible {
  var description: String {
    var comboDesc = ""
    
    switch self {
    case .either(let mods):
      comboDesc = "either \(mods.symbolNames.joined(separator: " or "))"
    case .any(let mods):
      comboDesc = "any of \(mods.symbolNames.joined(separator: " or "))"
    case .all(let mods):
      comboDesc = "all of \(mods.symbolNames.joined(separator: " and "))"
    case .none(let mods):
      comboDesc = "not \(mods.symbolNames.joined(separator: " or "))"
    }
    
    return "KeyCombinations(\(comboDesc))"
  }
}


enum KeyStatus: String, RawRepresentable {
  case held = "Pressed"
  case released = "Unpressed"
  
  init(rawValue: Bool) {
    self = KeyStatus.fromBool(rawValue)
  }
  
  static func fromBool(_ val: Bool) -> KeyStatus {
    switch val {
    case true: return .held
    case false: return .released
    }
  }
}

@Observable
final class ModKeyState: ModKeyStatusReportable {
  
  @ObservationIgnored
  private var cancellable: Any?

  var modifierFlags = NSEvent.ModifierFlags([])
  
  var modifiers: EventModifiers {
    EventModifiers(modifierFlags: modifierFlags)
  }

  init() {
    self.cancellable = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
      self?.modifierFlags = event.modifierFlags
      return event;
    }
  }
  
  deinit { NSEvent.removeMonitor(self.cancellable!) }
  
  func status(_ mod: NSEvent.ModifierFlags) -> KeyStatus {
    modifierFlags.status(mod)
  }

  func isPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    modifierFlags.isPressed(mod)
  }
  
  func isPressed(_ mod: NSEvent.ModifierFlags, with keyset: KeyCombinations) -> Bool {
    modifierFlags.isPressed(mod, with: keyset)
  }
  
  func isPressed(_ keyset: KeyCombinations) -> Bool {
    modifierFlags.isPressed(keyset)
  }
  
  func exclusivePressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    modifierFlags.exclusivePressed(mod)
  }
  
  func notPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    modifierFlags.notPressed(mod)
  }
}
