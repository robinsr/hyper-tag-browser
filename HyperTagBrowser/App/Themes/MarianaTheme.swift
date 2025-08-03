// created on 9/26/24 by robinsr

import SwiftUI

class MarianaTheme: ColorTheme  {
  static let grayChateau        = ThemeColorOption(name: "Gray Chateau", red: 0.6471, green: 0.6745, blue: 0.7294)
  static let bunker             = ThemeColorOption(name: "Bunker", red: 0.0471, green: 0.0627, blue: 0.0902)
  static let shark              = ThemeColorOption(name: "Shark", red: 0.1419, green: 0.1611, blue: 0.1818)
  static let outerSpace         = ThemeColorOption(name: "Outer Space", red: 0.1804, green: 0.2196, blue: 0.2588)
  static let burntUmber         = ThemeColorOption(name: "Burnt Umber", red: 0.51, green: 0.1546, blue: 0.1988)
  static let stiletto           = ThemeColorOption(name: "Stiletto", red: 0.6375, green: 0.1933, blue: 0.2485)
  static let flushMahogany      = ThemeColorOption(name: "Flush Mahogany", red: 0.7969, green: 0.2416, blue: 0.3106)
  static let carnation          = ThemeColorOption(name: "Carnation", red: 0.9961, green: 0.302, blue: 0.3882)
  static let mediumCarmine      = ThemeColorOption(name: "Medium Carmine", red: 0.64, green: 0.2786, blue: 0.2033)
  static let mojo               = ThemeColorOption(name: "Mojo", red: 0.8, green: 0.3482, blue: 0.2541)
  static let persimmon          = ThemeColorOption(name: "Persimmon", red: 1.0, green: 0.4353, blue: 0.3176)
  static let yellowOrange       = ThemeColorOption(name: "Yellow Orange", red: 1.0, green: 0.6667, blue: 0.2941)
  static let macaroniAndCheese  = ThemeColorOption(name: "Macaroni and Cheese", red: 1.0, green: 0.7333, blue: 0.4353)
  static let moonraker          = ThemeColorOption(name: "Moonraker", red: 0.7922, green: 0.8275, blue: 0.9608)
  static let deYork             = ThemeColorOption(name: "De York", red: 0.5451, green: 0.7922, blue: 0.5686)
  static let amulet             = ThemeColorOption(name: "Amulet", red: 0.4361, green: 0.6337, blue: 0.4549)
  static let pelorous           = ThemeColorOption(name: "Pelorous", red: 0.2235, green: 0.7176, blue: 0.7098)
  static let danube             = ThemeColorOption(name: "Danube", red: 0.3451, green: 0.6039, blue: 0.8118)
  static let sanMarino          = ThemeColorOption(name: "San Marino", red: 0.2761, green: 0.4831, blue: 0.6494)
  static let bismark            = ThemeColorOption(name: "Bismark", red: 0.2475, green: 0.4023, blue: 0.5079)
  static let pickledBluewood    = ThemeColorOption(name: "Pickled Bluewood", red: 0.1485, green: 0.2414, blue: 0.3047)
  static let ebonyClay          = ThemeColorOption(name: "Ebony Clay", red: 0.1564, green: 0.1631, blue: 0.231)
  static let steelGray          = ThemeColorOption(name: "Steel Gray", red: 0.1177, green: 0.1203, blue: 0.1713)
  static let strikemaster       = ThemeColorOption(name: "Strikemaster", red: 0.5195, green: 0.3614, blue: 0.502)
  static let bouquet            = ThemeColorOption(name: "Bouquet", red: 0.6494, green: 0.4518, blue: 0.6275)
  static let viola              = ThemeColorOption(name: "Viola", red: 0.8118, green: 0.5647, blue: 0.7843)
  
  static let allCases: [ThemeColorOption] = [
    moonraker,
    grayChateau,
    bunker,
    shark,
    outerSpace,
    burntUmber,
    stiletto,
    flushMahogany,
    carnation,
    mediumCarmine,
    mojo,
    persimmon,
    yellowOrange,
    macaroniAndCheese,
    deYork,
    amulet,
    pelorous,
    danube,
    sanMarino,
    bismark,
    pickledBluewood,
    ebonyClay,
    steelGray,
    strikemaster,
    bouquet,
    viola,
  ]
  
  let name = "Mariana Color Theme"
  
  var colors: [ThemeColorOption] { Self.allCases }
  
  var info: Color { Self.danube.asColor }
  var success: Color { Self.amulet.asColor }
  var danger: Color { Self.persimmon.asColor }
  var error: Color { Self.burntUmber.asColor }
  
  var themeKeys: [String] { Self.allCases.map(\.name) }
  
  var themeColors: Dictionary<String, ThemeColorOption> {
    .init(uniqueKeysWithValues: Self.allCases.map{ ($0.name, $0) })
  }
  
  var asSelectables: [SelectOption<ThemeColorOption>] {
    Self.allCases.map { .init(value: $0, label: $0.name) }
  }

  func color(key: String) -> ThemeColorOption {
    if let match = Self.allCases.first(where: { $0.name == key }) {
      return match
    }
    return .nothing
  }
  
  func color(for other: Color) -> ThemeColorOption? {
    Self.allCases.first { $0.asColor == other }
  }

  func background(for scheme: ColorScheme) -> Color {
    switch scheme {
    case .light:
      return Self.grayChateau.asColor
    case .dark:
      return Self.shark.asColor
    default:
      return Self.shark.asColor
    }
  }
  
  func foreground(for scheme: ColorScheme) -> Color {
    switch scheme {
    case .light:
      return Self.bunker.asColor
    case .dark:
      return Self.grayChateau.asColor
    default:
      return Self.grayChateau.asColor
    }
  }
  
  func option(key: String) -> SelectOption<ThemeColorOption> {
    asSelectables.first { $0.value.name == key } ?? .nothingOption
  }
  
  func option(for other: Color) -> SelectOption<ThemeColorOption> {
    let otherHash = other.hashValue
    
    return asSelectables.first { $0.value.asColor.hashValue == otherHash } ?? .nothingOption
  }
}
