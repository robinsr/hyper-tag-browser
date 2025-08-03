// created on 5/24/25 by robinsr

import SwiftUI


/**
 * A ViewModifier that listens for the escape key and dispatches a dismiss action.
 */
struct EscapeKeyHandlerViewModifier: ViewModifier {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.modifierKeys) var mods
  
  func body(content: Content) -> some View {
    content
      .viewKeyBinding(.dismiss, mods) {
        dispatch(.dismissRequested)
      }
  }
}

extension View {
  /// Adds a modifier to handle escape key presses to dismiss the current view.
  func withEscapeKeyHandler() -> some View {
    self.modifier(EscapeKeyHandlerViewModifier())
  }
}
