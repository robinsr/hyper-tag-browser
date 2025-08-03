// created on 2/6/25 by robinsr

import Foundation


enum AppStage: String {
  case dev = "alpha"
  case test = "beta"
  case prod = "release"
  
  case _preview = "preview"
  
  static var isUnitTest: Bool {
    NSClassFromString("XCTestCase") != nil
  }
  
  var displayName: String {
    self.rawValue
  }
  
  var isDev: Bool { self == .dev }
  var isTest: Bool { self == .test }
  var isProd: Bool { self == .prod }
  var isAlpha: Bool { self == .dev }
  var isBeta: Bool { self == .test }
  var isRelease: Bool { self == .prod }
  
  var bundleName: String {
    switch self {
    case ._preview: "TaggedFileBrowserPreview"
    case .dev: "TaggedFileBrowserAlpha"
    case .test: "TaggedFileBrowserBeta"
    case .prod: "TaggedFileBrowser"
    }
  }
}

extension AppStage: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    switch value.lowercased() {
    case "dev", "alpha":
      self = .dev
    case "test", "beta":
      self = .test
    case "prod", "release":
      self = .prod
    default:
      fatalError("Invalid AppStage value: \(value)")
    }
  }
}
