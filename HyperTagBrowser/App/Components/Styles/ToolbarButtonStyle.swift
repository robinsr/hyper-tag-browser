// created on 11/22/24 by robinsr

import SwiftUI


struct ToolbarButtonStyle: ButtonStyle, ColorAwareButton {
  @Environment(\.colorModel) var bgColor
  @State var isHovered = false
  
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(hoveredStateColor)
      .padding(.horizontal, 4)
      .pointerStyle(.link)
  }
}


extension ButtonStyle where Self == ToolbarButtonStyle {
  
  /**
   * Applies ``ToolbarButtonStyle``
   */
  static var toolbarBtn: Self { ToolbarButtonStyle() }
}
