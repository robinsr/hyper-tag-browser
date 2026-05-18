// created on 2/6/25 by robinsr

import Foundation


enum AppStage: String {
  case release = "release"
  case debug = "debug"
  case _preview = "preview"
  
  static var isUnitTest: Bool {
    NSClassFromString("XCTestCase") != nil
  }
  
  var displayName: String {
    self.rawValue
  }
  
  var isRelease: Bool { self == .release }
  var isDebug: Bool { self == .debug }
  var isPreview: Bool { self == ._preview }
  
  
  var bundleName: String {
    switch self {
    case ._preview: 
      return "\(Constants.appname)Previews"
    case .debug: 
      return "\(Constants.appname)Debug"
    default:
      return Constants.appname
    }
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
