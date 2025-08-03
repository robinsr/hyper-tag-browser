// created on 5/31/25 by robinsr

import SwiftUI


/**
 * A custom `ToggleStyle` for toolbar buttons that changes appearance based on hover state.
 */
public struct ToolbarToggleStyle: ToggleStyle, ColorAwareButton {
  @Environment(\.colorModel) var bgColor
  @State var isHovered = false
  
  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(configuration.isOn ? enhancedColor : hoveredStateColor)
      .padding(.horizontal, 4)
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
      .onTapGesture {
        configuration.isOn.toggle()
      }
  }
}


extension ToggleStyle where Self == ToolbarToggleStyle {
  
  /**
   * Applies toggleStyle ``ToolbarToggleStyle``
   */
  static var toolbar: Self { ToolbarToggleStyle() }
}
