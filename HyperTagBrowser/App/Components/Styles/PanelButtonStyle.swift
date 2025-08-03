// created on 4/30/25 by robinsr

import SwiftUI


struct PanelButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(StyleClass.listEditorInput.font)
      .foregroundStyle(.primary.opacity(0.3))
      .buttonStyle(.plain)
      .labelStyle(.iconOnly)
      .pointerStyle(.link)
  }
}

extension ButtonStyle where Self == PanelButtonStyle {
    /// Applies the style ``PanelButtonStyle`` to a `Button`
  static var closePanel: Self { PanelButtonStyle() }
}
