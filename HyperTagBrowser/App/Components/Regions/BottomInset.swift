// created on 10/13/24 by robinsr

import SwiftUI

struct VerticalInsetModifier<InnerContent: View> : ViewModifier {
  let edge: VerticalEdge
  
  @ViewBuilder let insetContent: () -> InnerContent
  
  func body(content: Content) -> some View {
    content
      .safeAreaInset(edge: edge) {
        insetContent()
      }
  }
}

struct HorizontalInsetModifier<InnerContent: View> : ViewModifier {
  let edge: HorizontalEdge
  
  @ViewBuilder let insetContent: () -> InnerContent
  
  func body(content: Content) -> some View {
    content
      .safeAreaInset(edge: edge) {
        insetContent()
      }
  }
}

extension View {
  func bottomInset<Content: View>(
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    return modifier(VerticalInsetModifier(edge: .bottom, insetContent: content))
  }
  
  func topInset<Content: View>(
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    return modifier(VerticalInsetModifier(edge: .top, insetContent: content))
  }
  
  func leftInset<Content: View>(
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    return modifier(HorizontalInsetModifier(edge: .leading, insetContent: content))
  }
  
  func rightInset<Content: View>(
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    return modifier(HorizontalInsetModifier(edge: .trailing, insetContent: content))
  }
}
