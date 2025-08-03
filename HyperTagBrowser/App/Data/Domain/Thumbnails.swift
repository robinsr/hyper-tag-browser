// Created on 9/7/24 by robinsr

import Defaults
import Foundation
import QuickLookThumbnailing


enum ThumbnailQuality: String, Defaults.Serializable, CaseIterable, SelectableOptions {
  case low = "Low"
  case medium = "Medium"
  case high = "High"
  
  var size: CGSize {
    let maxSize = Constants.maxTileSize
    
    switch self {
      case .low: return CGSize(widthHeight: maxSize / 3)
      case .medium: return CGSize(widthHeight: maxSize / 2)
      case .high: return CGSize(widthHeight: maxSize)
    }
  }
  
  static var asSelectables: [SelectOption<Self>] {
    allCases.map { SelectOption(value: $0, label: $0.rawValue) }
  }
}



extension QLThumbnailRepresentation.RepresentationType : @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
      case .icon: return "Icon"
      case .thumbnail: return "Thumbnail"
      case .lowQualityThumbnail: return "LowQ Thumbnail"
    @unknown default:
      return "Unknown"
    }
  }
}
