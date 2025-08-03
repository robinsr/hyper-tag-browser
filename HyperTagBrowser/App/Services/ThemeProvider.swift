// created on 9/26/24 by robinsr

import SwiftUI


struct ThemeProvider {
  static var shared = ThemeProvider()
  
  // TODO: Make this a user setting somehow
  var current: ColorTheme { MarianaTheme() }
  var info: Color { current.info }
  var success: Color { current.success }
  var danger: Color { current.danger }
  var error: Color { current.error }
  
  func background(_ scheme: ColorScheme) -> Color {
    current.background(for: scheme)
  }
  
  func foreground(_ scheme: ColorScheme) -> Color {
    current.foreground(for: scheme)
  }
  
}
