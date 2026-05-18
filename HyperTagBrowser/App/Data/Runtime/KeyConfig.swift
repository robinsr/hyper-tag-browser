// created on 1/17/26 by robinsr

import SwiftUI

/**
 * Container for passing a keyboard shortcut to a View
 */
enum KeyConfig {

  case binding(KeyBinding)
  case shortcut(KeyboardShortcut)
  case indexed(Int, EventModifiers)
  case none

  var isPresent: Bool {
    switch self {
    case .binding(_), .shortcut(_):
      return true
    case .indexed(let index, _):
      return index >= 0 && index < 10
    case .none:
      return false
    }
  }

  var binding: KeyBinding? {
    switch self {
    case .binding(let binding):
      return binding
    case .shortcut(let shortcut):
      return KeyBinding.init(shortcut.key, shortcut.modifiers)
    case .indexed(let index, let mods):
      guard 0...10 ~= index else { return nil }
      return KeyBinding.indexed(index, mods)
    case .none:
      return nil
    }
  }
}
