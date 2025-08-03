// created on 5/4/25 by robinsr

import Defaults
import SwiftUI

enum ColorSchemePreference: String, Defaults.Serializable, CaseIterable, Identifiable {
  case system, light, dark
  
  var id: String { rawValue }
  
  func applyUserPref(_ scheme: ColorScheme) -> ColorScheme {
    switch self {
    case .system: return scheme
    case .light: return .light
    case .dark: return .dark
    }
  }
}

extension ColorSchemePreference: CustomStringConvertible {
  var description: String {
    switch self {
    case .system: return "Use System Theme"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }
}

extension ColorSchemePreference: SelectableOptions {
  typealias VType = ColorSchemePreference
  
  static var asSelectables: [SelectOption<ColorSchemePreference>] {
    allCases.map { SelectOption(value: $0, label: $0.description) }
  }
}
