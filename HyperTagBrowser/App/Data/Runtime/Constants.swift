// Created on 9/2/24 by robinsr

import CoreGraphics
import CustomDump
import Foundation
import GRDB
import SwiftUI
import System


struct Constants {
  static let appname = "TaggedFileBrowser"
  static let appdomain = "com.taggedfilebrowser"
  
  // DONT USER - get ALL environment info from EnvContainer
  // static let bundleId = Bundle.main.bundleIdentifier ?? appdomain

  static let fileDialogId = "com.taggedfilebrowser.filedialog"
  static let xContentIdKey = "\(appdomain).contentID"
  
  static let noContentId = "\(appdomain).nocontent"
  
  static let workspaceFilepath: FilePath = {
    var fullpath = FilePath(#file)
    var rootpath = fullpath
    
    while rootpath.components.count > 0 && rootpath.lastComponent?.string != Constants.appname {
      rootpath.removeLastComponent()
    }
    
    print("Workspace root FilePath: \(rootpath.string)")
    
    return rootpath
  }()
  
  static let maxFileSizeForContentId = 10_000_000
  
  static let minWindowSize = CGSize(width: 768, height: 510)
  
  static let smallScreenThreshold = 600.0
  
  static let thumbnailDataSize = CGSize(width: 256, height: 256)
  
  static let minTileSize: Double = 120
  static let maxTileSize: Double = 380
  static let defaultTileSize: Double = 200
  static let defaultTileInset: Double = 7.5
  static let defaultTileSpacing: Double = 2.5
  
  static let minColorBrightnessHoverState: Double = 0.3
  static let minColorBrightnessForLightScheme: Double = 0.82
  
  static let darkModeBackgroundMixColor: Color = .black
  static let darkModeBackgroundMixAmount: Double = 0.3
  
  static let domColorSource: CGImage.DominantColorSource = .dominantColors
  
  static let jpegImportCompressionQuality: CGFloat = 0.9
  
  static let panelAnimationDuration: Double = 0.25
  static let panelShadowDepth: Double = 6
  static let panelAnimationTransition: Animation = .timingCurve(.circularEaseInOut, duration: panelAnimationDuration)
  
  static let bodyFontPointSize: CGFloat = NSFont.systemFontSize(for: .regular) * (NSScreen.main?.backingScaleFactor ?? 1)
  
  static let minIconSize: CGFloat = NSFont.systemFontSize(for: .mini) * (NSScreen.main?.backingScaleFactor ?? 1) - 10
  
  static let maxIconSize: CGFloat = NSFont.systemFontSize(for: .regular) * (NSScreen.main?.backingScaleFactor ?? 1) - 10
  
  static let userDateFormat = "M/d/yyyy"
  static let isoDateFormat = "yyyy-MM-dd"
  
  static let emptyImageURL = Bundle.main.url(forResource: "bg-dark-10x10", withExtension: "png")!
  
  static let prettyJSON = JSONEncoder.prettyPrinter
  
  static let grdbJsonDumpFormat = GRDB.JSONDumpFormat(encoder: Constants.prettyJSON)
}

extension Bundle {
  var cfBundleName: String {
    object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown"
  }
  
  var cfBundleVersion: String {
    object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
  }
  
  var cfBundleIdentifier: String {
    object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "Unknown"
  }
}
