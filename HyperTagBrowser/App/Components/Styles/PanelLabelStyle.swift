// created on 4/30/25 by robinsr

import SwiftUI


struct PanelLabelStyle: LabelStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.icon
      .font(.title)
      .foregroundStyle(.primary.opacity(0.3))
      .contentShape(Rectangle())
  }
}

extension LabelStyle where Self == PanelLabelStyle {
    /// Applies the style ``PanelLabelStyle`` to a `Label`
  static var closePanel: Self { PanelLabelStyle() }
}
