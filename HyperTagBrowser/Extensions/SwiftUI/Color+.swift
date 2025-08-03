// created on 1/8/25 by robinsr

import SwiftUI
// import AppKit



extension Color {
  var nsColor: NSColor {
    NSColor(self)
  }
  
  func lighten(by percentage: Double) -> Color {
    self.mix(with: .white, by: percentage)
  }
  
  func darken(by percentage: Double) -> Color {
    self.mix(with: .black, by: percentage)
  }
  
  func backgroundGradient(contrast: Double = 0.1) -> LinearGradient {
    let gradient = Gradient(colors: [
      self,
      self.mix(with: .black, by: contrast, in: .perceptual)
    ])

    return LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
  }
  
  /// A color to use as the foreground for text placed on top of this color
  var foreground: Color {
    nsColor.foreground.asColor
  }
  
  /// Is this foreground color (see .foreground) generally dark or light?
  var foregroundScheme: ColorScheme {
    nsColor.foregroundScheme
  }
  
  /// Is this color generally dark or light?
  var colorScheme: ColorScheme {
    nsColor.colorScheme
  }
  
  var brightnessComponent: CGFloat {
    nsColor.usingColorSpace(.sRGB)?.brightnessComponent ?? 0
  }
}
