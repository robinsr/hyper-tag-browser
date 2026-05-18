// created on 2/6/25 by robinsr

import Foundation


enum AppStage: String, Identifiable {
  case release = "release"
  case debug = "debug"
  case _preview = "preview"
  
  var id: String {
    self.rawValue
  }
  
  var isRelease: Bool { self == .release }
  var isDebug: Bool { self == .debug }
  var isPreview: Bool { self == ._preview }
  
  
  var bundleName: String {
    switch self {
    case ._preview: 
      return "\(Constants.appDisplayName)Previews"
    case .debug: 
      return "\(Constants.appDisplayName)Debug"
    default:
      return Constants.appDisplayName
    }
  }
  
  static var isUnitTest: Bool {
    NSClassFromString("XCTestCase") != nil
  }
}

extension AppStage: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    switch value.lowercased() {
    case "preview":
      self = ._preview
    case "test", "debug":
      self = .debug
    case "prod", "release":
      self = .release
    default:
      fatalError("Invalid AppStage value: \(value)")
    }
  }
}
