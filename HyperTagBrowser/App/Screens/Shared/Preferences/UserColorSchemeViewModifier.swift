// created on 5/4/25 by robinsr

import Defaults
import Factory
import SwiftUI


struct UserColorSchemeViewModifier: ViewModifier {
  @Environment(\.colorScheme) var systemScheme
  @Default(.preferredScheme) var preferredScheme

  func body(content: Content) -> some View {
    content
      .colorScheme(preferredScheme.applyUserPref(systemScheme))
  }
}

extension View {
  func withUserColorScheme() -> some View {
    modifier(UserColorSchemeViewModifier())
  }
}
