// created on 5/9/25 by robinsr

import Factory
import SwiftUI
import OSLog


extension View {

  /// Applies a `KeyboardShortcut`-based keyboard shortcut to the view
  func buttonShortcut(
    shortcut: KeyboardShortcut,
    action: @escaping () -> Void
  ) -> some View {
    overlay {
      Button("") {
        action()
      }
      .labelsHidden()
      .opacity(0)
      .frame(width: 0, height: 0)
      .keyboardShortcut(shortcut)
      .accessibilityHidden(true)
    }
  }
  
  /// Applies a `KeyBinding`-based keyboard shortcut to the view
  func buttonShortcut(
    binding: KeyBinding?,
    action: @escaping () -> Void
  ) -> some View {
    self.modify(when: binding != nil) { view in
      view.buttonShortcut(
        shortcut: binding!.keyboardShortcut,
        action: action
      )
    }
  }
  
  /// Applies a `KeyEquivalent`- and `EventModifier`- based keyboard shortcut to the view
  func buttonShortcut(
    key: KeyEquivalent,
    modifiers: EventModifiers = .command,
    isEnabled: Bool = true,
    action: @escaping () -> Void
  ) -> some View {
    self.modify(when: isEnabled) { view in
      view.buttonShortcut(
        shortcut: KeyboardShortcut(key, modifiers: modifiers),
        action: action
      )
    }
  }
  
  func viewKeyBinding(_ binding: KeyBinding, _ modState: ModKeyState, action: @escaping () -> ()) -> some View {
    self.onKeyPress(binding.key, phases: [.up], action: { evt in
      if binding.mods == modState.modifiers && evt.phase == .up {
        action()
        return .handled
      } else {
        return .ignored
      }
    })
  }
}

