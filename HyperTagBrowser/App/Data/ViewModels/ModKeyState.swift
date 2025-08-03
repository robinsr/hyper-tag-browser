// created on 11/12/24 by robinsr

import SwiftUI

protocol KeyModifierList {
  func isPressed(_ mod: NSEvent.ModifierFlags) -> Bool
  func notPressed(_ mod: NSEvent.ModifierFlags) -> Bool
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
final class ModKeyState: KeyModifierList {
  
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
  
  var eventModifiers: EventModifiers {
    EventModifiers(modifierFlags: modifierFlags)
  }
  
  func isPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    return modifierFlags.contains(mod)
  }
  
  func isPressed(only mod: NSEvent.ModifierFlags) -> Bool {
    return modifierFlags.contains(mod) && modifierFlags.subtracting(mod).isEmpty
  }
  
  func notPressed(_ mod: NSEvent.ModifierFlags) -> Bool {
    return !isPressed(mod)
  }
}
