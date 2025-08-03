// created on 5/31/25 by robinsr

import SwiftUI


struct ToolbarMenuStyle : MenuStyle, ColorAwareButton {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.colorModel) var bgColor
  @State var isHovered = false
  
  var hoverEffect = true
  
  public func makeBody(configuration: Configuration) -> some View {
    return Menu(configuration)
      .menuIndicator(.hidden)
      .foregroundColor(hoveredStateColor)
      .buttonStyle(.borderless)
      .pointerStyle(.link)
      .labelStyle(ToolbarLabelStyle())
      .onHover { inside in
        if hoverEffect && inside {
          isHovered = true
        } else {
          isHovered = false
        }
      }
  }
}



extension MenuStyle where Self == ToolbarMenuStyle {
  
  /**
   * Applies menuStyle ``ToolbarMenuStyle``
   */
  static var toolbar: Self { ToolbarMenuStyle() }
}
