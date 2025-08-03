// created on 9/17/24 by robinsr

import SwiftUI
import Defaults


struct BackgroundGradientView<Content: View>: View {
  @Environment(\.colorScheme) var colorScheme
  
  var color: Color
  var opacity: Double = 1.0
  var intensity: Double = 0.1
  var useMaterial: Bool = true
  
  @ViewBuilder let content: () -> (Content)
  
  var overlayMixAmount: Double {
    switch colorScheme {
      case .dark: return Constants.darkModeBackgroundMixAmount
      default: return 0.0
    }
  }
  
  var overlayColor: Color {
    Color.black.opacity(overlayMixAmount)
  }
  
  var bgOpacity: Double {
    if opacity.isBetween(0...1) {
      return opacity
    } else {
      return opacity/100
    }
  }

  var body: some View {
    Group {
      if useMaterial {
        PanelMaterialView {
          GradientStack
        }
      } else {
        GradientStack
      }
    }
    .edgesIgnoringSafeArea(.top)
  }
  
  var GradientStack: some View {
    ZStack {
      Rectangle()
        .fill(color.backgroundGradient(contrast: intensity))
        .animation(.smooth(duration: 1.0), value: color)
        .opacity(bgOpacity)
        
      Rectangle()
        .fill(overlayColor)
      
      content()
    }
  }
}


/**
 A view that applies a background gradient based on the `backgroundColor` environment value.
 */
struct ActiveBackgroundGradientModifier: ViewModifier {
  @Environment(\.colorModel) var bgColor
  @Default(.backgroundOpacity) var bgOpacity
  
  func body(content: Content) -> some View {
    BackgroundGradientView(color: bgColor.color, opacity: bgOpacity) {
      content
    }
    .edgesIgnoringSafeArea(.top)
  }
}


/**
 A View that applies a background gradient based on the user's preferences pulled from `Defaults`.
 */
struct UserPrefBackgroundGradientModifier: ViewModifier {
  @Default(.backgroundColor) var bgColor
  @Default(.backgroundOpacity) var bgOpacity
  
  func body(content: Content) -> some View {
    BackgroundGradientView(color: bgColor, opacity: bgOpacity) {
      content
    }
    .edgesIgnoringSafeArea(.top)
  }
}


extension View {
  
  /**
    Applies a background gradient based on the `backgroundColor` environment value.
   */
  func withEnvironmentBackgroundColor() -> some View {
    modifier(ActiveBackgroundGradientModifier())
  }
  
  /**
    Applies a background gradient based on the user's preferences pulled from `Defaults`.
   */
  func withUserPrefBackgroundColor() -> some View {
    modifier(UserPrefBackgroundGradientModifier())
  }
}
