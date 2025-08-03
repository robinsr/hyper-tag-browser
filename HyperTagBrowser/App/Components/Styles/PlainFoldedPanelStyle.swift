// created on 4/30/25 by robinsr

import SwiftUI


struct PlainFoldedPanelStyle: FoldedPanelStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.content
      .padding(.vertical, 12)
      .padding(.horizontal, 10)
      .background(VisualEffectView(blendingMode: .behindWindow))
      .colorScheme(.dark)
  }
}

extension FoldedPanelStyle where Self == PlainFoldedPanelStyle {
  
    /// Applies the style ``PlainFoldedPanelStyle`` to a `FoldedPanel`
  static var plain: Self { PlainFoldedPanelStyle() }
}
