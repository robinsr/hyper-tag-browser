// created on 9/18/24 by robinsr

import SwiftUI


struct FoldedPanel<Content: View>: View {
  @Environment(\.foldedPanelStyle) private var style
  
  @Binding var isPresented: Bool
  @ViewBuilder let content: () -> (Content)
  
  let shadowDepth: Double = 6
  
  var StyledInnerContent: some View {
    AnyView(style.resolve(
      configuration: FoldedPanelStyleConfiguration(
        content: content()
          .fillFrame(.horizontal)
      ))
    )
  }
  
  var body: some View {
    VStack {
      VStack {
        StyledInnerContent
      }
      .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: isPresented ? .none : 0)
      .clipped()
      .animation(Constants.panelAnimationTransition, value: isPresented)
      .transition(.slide)
    }
    .zIndex(isPresented ? 0 : -1)
    .accessibilityLabel(isPresented ? "Folding section open" : "Folding section closed")
  }
}
