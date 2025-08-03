// created on 11/22/24 by robinsr

import SwiftUI


public struct ToolbarIconButtonStyle: ButtonStyle, ColorAwareButton {
  @Environment(\.colorModel) var bgColor
  @Environment(\.enabledFlags) var devFlags
  
  @State var isHovered = false
  
  var debugToolbar: Bool {
    devFlags.contains(.views_debugToolbar)
  }
  
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .if(debugToolbar) {
        $0.labelStyle(.titleAndIcon)
      } else: {
        $0.labelStyle(.iconOnly)
      }
      .foregroundStyle(hoveredStateColor)
      .padding(.horizontal, 4)
      .pointerStyle(.link)
      .scaleEffect(scaleValue)
      .animation(.snappy(duration: 0.25, extraBounce: 0.25), value: scaleValue)
      .onHover { inside in
        isHovered = inside
      }
  }
}


extension ButtonStyle where Self == ToolbarIconButtonStyle {
  
  /**
   * Applies ``ToolbarIconButtonStyle``
   */
  static var toolbarIcon: Self { ToolbarIconButtonStyle() }
}
