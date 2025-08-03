import AppKit
import SwiftUI


protocol ColorAwareButton: Sendable {
  @MainActor var bgColor: DominantColorViewModel { get }
  @MainActor var isHovered: Bool { get }
}


extension ColorAwareButton {
  var minBrightness: Double {
    Constants.minColorBrightnessHoverState
  }
  
  @MainActor
  var enhancedColor: Color {
    if bgColor.color.brightnessComponent > minBrightness {
      return bgColor.color
    } else {
      return .primary
    }
  }
  
  @MainActor
  var hoveredStateColor: Color {
    isHovered ? enhancedColor : .primary
  }
  
  @MainActor
  var scaleValue: Double {
    isHovered ? 1.2 : 1.0
  }
}
