// created on 5/9/25 by robinsr

import SwiftUI


extension SwiftUI.Button {
  
    /// Applies a `KeyBinding`-based keyboard shortcut to the Button
  func keyboardShortcut(_ binding: KeyBinding, helpText: String? = nil) -> some View {
    self
      .keyboardShortcut(binding.keyboardShortcut)
      .help(helpText ?? binding.description)
  }
}
