// created on 1/12/26 by robinsr

import SwiftUI

struct SyncHoverModifier: ViewModifier {
  @Binding var isHovered: Bool
  
  func body(content: Content) -> some View {
    content
      .onHover {
        isHovered = $0
      }
  }
}

extension View {
  func syncHover(to binding: Binding<Bool>) -> some View {
    modifier(SyncHoverModifier(isHovered: binding))
  }
  
  func bindHover(to binding: Binding<Bool>) -> some View {
    modifier(SyncHoverModifier(isHovered: binding))
  }
}
