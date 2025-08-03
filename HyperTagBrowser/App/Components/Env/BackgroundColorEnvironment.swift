// Created by robinsr on 9/15/24.

import SwiftUI
import Defaults


struct BackgroundColorEnvironmentViewModifier: ViewModifier {
  @Environment(\.colorModel) var model
  @Environment(\.enabledFlags) var devFlags
  
  
  var isEnabled: Bool {
    devFlags.contains(.enable_dominantColor)
  }
  
  func body(content: Content) -> some View {
    content
      
  }
}


