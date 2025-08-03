// created on 5/9/25 by robinsr

import SwiftUI


extension SwiftUI.Toggle {
  
    /// Applies a `KeyBinding`-based keyboard shortcut to the Toggle
  func keyboardShortcut(_ binding: KeyBinding, helpText: String? = nil) -> some View {
    self
      .keyboardShortcut(binding.keyboardShortcut)
      .help(helpText ?? binding.description)
  }
}
