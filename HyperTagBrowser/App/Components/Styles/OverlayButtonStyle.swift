// created on 11/22/24 by robinsr

import SwiftUI


struct OverlayButtonStyle: ButtonStyle {
  let opacity: Double
  
  init(opacity: Double = 0.6) {
    self.opacity = opacity
  }
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.title.weight(.light))
      .foregroundStyle(.primary.opacity(opacity))
      .buttonStyle(.plain)
      .labelStyle(.iconOnly)
      .pointerStyle(.link)
  }
}

extension ButtonStyle where Self == OverlayButtonStyle {
  
    /// Applies the style ``OverlayButtonStyle`` to a `Button`
  static var overlay: Self { OverlayButtonStyle() }
}
