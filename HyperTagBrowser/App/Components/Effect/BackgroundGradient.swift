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
  
  let darkOverColor: Color = .black.opacity(Constants.darkModeBackgroundMixAmount)
  
  var bgOpacity: Double {
    opacity.isBetween(0...1) ? opacity : opacity/100
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
        
      if colorScheme == .dark {
        Rectangle().fill(darkOverColor)
      }
      
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
  @available(*, deprecated, message: "Avoid using pending performance improvements. Use withUserPrefBackgroundColor() instead.")
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
