// created on 4/30/25 by robinsr

import SwiftUI

struct DarkFoldedPanelStyle: FoldedPanelStyle {
  
  let baseBackground: some ShapeStyle = BackgroundStyle.background
    .shadow(.inner(color: Color.black, radius: Constants.panelShadowDepth))
  
  let layerBackground: some ShapeStyle = Color.white.opacity(0.11)
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.content
      .padding(.vertical, 12)
      .padding(.horizontal, 10)
      .background(layerBackground, in: Rectangle())
      .background(baseBackground, in: Rectangle())
      .colorScheme(.dark)
  }
}

extension FoldedPanelStyle where Self == DarkFoldedPanelStyle {
  
    /// Applies the style ``DarkFoldedPanelStyle`` to a `FoldedPanel`
  static var darkened: Self { DarkFoldedPanelStyle() }
}
