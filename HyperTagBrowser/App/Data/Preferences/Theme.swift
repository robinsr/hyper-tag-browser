// Created on 9/2/24 by robinsr

import SwiftUI


protocol ColorOption: Hashable, Equatable {
  var name: String { get }
  var asColor: Color { get }
  var asGradient: LinearGradient { get }
  var nsColor: NSColor { get }
}


struct ThemeColorOption: ColorOption {
  var name: String
  var red: CGFloat = 0.0
  var green: CGFloat = 0.0
  var blue: CGFloat = 0.0
  var alpha: CGFloat = 1.0
  
  var asColor: Color {
    Color(red: red, green: green, blue: blue, opacity: alpha)
  }
  
  var nsColor: NSColor {
    NSColor(red: red, green: green, blue: blue, alpha: alpha)
  }
  
  var asGradient: LinearGradient {
    asColor.backgroundGradient()
  }
  
  static var nothing: Self {
    ThemeColorOption(name: "None", red: 1.0, green: 1.0, blue: 1.0, alpha: 0.00001)
  }
}


protocol ColorTheme {
  var name: String { get }
  var colors: [ThemeColorOption] { get }
  var themeColors: Dictionary<String, ThemeColorOption> { get }
  var themeKeys: Array<String> { get }
  
  var info: Color { get }
  var success: Color { get }
  var danger: Color { get }
  var error: Color { get }

  func foreground(for scheme: ColorScheme) -> Color
  func background(for scheme: ColorScheme) -> Color

  func color(key: String) -> ThemeColorOption
  func color(for: Color) -> (ThemeColorOption)?
  
  var asSelectables: [SelectOption<ThemeColorOption>] { get }

  func option(key: String) -> SelectOption<ThemeColorOption>
  func option(for: Color) -> SelectOption<ThemeColorOption>
}


extension SelectOption where Value == ThemeColorOption {
  static var nothingOption: SelectOption<ThemeColorOption> {
    .init(value: ThemeColorOption.nothing, label: ThemeColorOption.nothing.name)
  }
}
