// created on 9/15/24 by robinsr

import SwiftUI


/**
 * Adds a ModKeyState object to the environment.
 */
struct ModKeysPressedEnvironment: ViewModifier {
  @State var envState = ModKeyState()
  
  func body(content: Content) -> some View {
    content
      .environment(\.modifierKeys, envState)
  }
}

extension View {
  func withModifierKeyObserver() -> some View {
    modifier(ModKeysPressedEnvironment())
  }
}

extension EnvironmentValues {
  @Entry var modifierKeys = ModKeyState()
}
