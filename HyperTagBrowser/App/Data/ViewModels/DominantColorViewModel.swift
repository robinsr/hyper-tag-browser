// created on 2/18/25 by robinsr

import Factory
import SwiftUI


@Observable
final class DominantColorViewModel {
  
  @ObservationIgnored
  let blendColors = ColorSchemeSwitch(Color.white, Color.black)
  
  @ObservationIgnored
  let blendValues = ColorSchemeSwitch(0.5, 0.3)
  
  var colorSet: ImageColorSet
  var userPreferenceColor: Color = .clear
  var useTransparent: Bool = false
  var systemScheme: ColorScheme = .light
  var saturation: Double = 0.0
  
  var opacity: Double {
    useTransparent ? 0.0 : 0.5
  }
  
  var colors: [Color] {
    colorSet.components.map(\.asColor)
  }
  
  var dominantColor: Color {
    colorSet.forScheme(systemScheme)
  }
  
  var color: Color {
    dominantColor == .clear ? userPreferenceColor : dominantColor
  }
  
  var blendColor: Color {
    blendColors[systemScheme]
  }
  
  var blendValue: Double {
    blendValues[systemScheme]
  }
  
  var secondaryColor: Color {
    dominantColor
      .mix(with: blendColors[systemScheme], by: blendValues[systemScheme])
      .opacity(opacity)
  }
  
  var colorScheme: ColorScheme {
    if case .dark = systemScheme {
      return color.asDarkModeBackground.colorScheme
    }
    
    return color.colorScheme
  }
  
  init(colors: ImageColorSet? = nil) {
    self.colorSet = colors ?? .defaults
  }
  
  func reset() {
    self.colorSet = .defaults
  }
  
  func update(_ colors: ImageColorSet) {
    self.colorSet = colors
  }
  
  func update(_ userColor: Color) {
    self.userPreferenceColor = userColor
  }
  
  func update(_ scheme: ColorScheme) {
    self.systemScheme = scheme
  }
  
  func update(_ saturation: Double) {
    self.saturation = saturation
  }
  
  func update(_ useTransparent: Bool) {
    self.useTransparent = useTransparent
  }
}
