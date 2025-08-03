// created on 10/17/24 by robinsr

import SwiftUI
import Foundation

extension NSColor {
  static let darkModeBackgroundColor = NSColor(red: 0.1176, green: 0.1176, blue: 0.1176, alpha: 1.0)
  static let lightModeBackgroundColor = NSColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1.0)
}


extension NSColor {
  var hexString: String {
    // Convert components to int between 0 and 255
    let rInt = Int((redComponent * 255.99999))
    let gInt = Int((greenComponent * 255.99999))
    let bInt = Int((blueComponent * 255.99999))
    
    // Convert the numbers to hex strings
    let rHex = String(format: "%02x", rInt)
    let gHex = String(format: "%02x", gInt)
    let bHex = String(format: "%02x", bInt)
    
    return "\(rHex)\(gHex)\(bHex)"
  }
  
  
  var asColor: Color {
    Color(nsColor: self)
  }
  
  var complimentaryColor: NSColor {
    cgColor.complementaryColor.asNSColor
  }
  
  
  /**
   Keeps the same basic color value but adjusts it to be easier on the eyes. This is intended to be used as a
   background color in place of the original color in dark-mode settings
   */
  var asDarkModeBackground: NSColor {
    asColor.asDarkModeBackground.nsColor
  }
  
  var colorScheme: ColorScheme {
    let cutover = Constants.minColorBrightnessForLightScheme 
    
    let rgbColor = usingColorSpace(.sRGB) ?? NSColor.textColor

    if (rgbColor.brightnessComponent > cutover) {
      // Color is bright, suitable for light scheme
      return .light
    } else {
      // Color is dark, suitable for dark scheme
      return .dark
    }
  }
  
  var foregroundScheme: ColorScheme {
    return colorScheme == .light
      // Color is bright, use contrasting dark text/foreground color
      ? .dark
      // Color is dark, use contrasting light text/foreground color
      : .light
  }
  
  
  /// A color to use as the foreground for text placed on top of this color
  var foreground: NSColor {
    // This will be the same color in either case, but the system will swap them
    // when system color scheme changes. For a static color, the recommended color
    // should stay constant, therefore this switch needs to select appropriate
    // semanatic color but it should always be the same value
    let overLightColor = colorScheme == .light
      ? Color.primary.nsColor
      : Color.secondary.nsColor
    
    let overDarkColor = colorScheme == .light
      ? Color.secondary.nsColor
      : Color.primary.nsColor
    
    if self.foregroundScheme == .dark {
      return overDarkColor
    } else {
      return overLightColor
    }
  }
}
