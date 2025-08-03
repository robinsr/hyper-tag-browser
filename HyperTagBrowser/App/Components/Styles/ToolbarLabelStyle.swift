// created on 5/31/25 by robinsr

import SwiftUI


struct ToolbarLabelStyle : LabelStyle, ColorAwareButton {
  @Environment(\.colorModel) var bgColor
  @State var isHovered = false
  
  public func makeBody(configuration: Configuration) -> some View {
    configuration.icon
      .foregroundColor(hoveredStateColor)
      .pointerStyle(.link)
      .scaleEffect(scaleValue)
      .animation(.snappy(duration: 0.25, extraBounce: 0.25), value: scaleValue)
      .onHover { inside in
        if inside {
          isHovered = true
        } else {
          isHovered = false
        }
      }
  }
}


extension LabelStyle where Self == ToolbarLabelStyle {
  /**
   * Applies labelStyle ``ToolbarLabelStyle``
   */
  static var toolbar: Self { ToolbarLabelStyle() }
}
