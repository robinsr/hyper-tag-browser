// created on 1/25/25 by robinsr

import Defaults


/**
 A `UserPrefSet` where the preference value is a boolean "on/off" 
 */
enum UserToggles: String, Defaults.Serializable, CaseIterable, UserPrefSet {
  case persistLocation
  case persistInspectorState
  case showTagCountOnTiles
  case showTagUsageCounts
  case seamlessGrid
  
  var id: String { rawValue }
  
  var label: String {
    switch self {
    case .persistLocation:
      return "Remember location"
    case .persistInspectorState:
      return "Remember inspector state"
    case .showTagCountOnTiles:
      return "Show Tag Count on Image Tiles"
    case .showTagUsageCounts:
      return "Show Tag Usage Counts"
    case .seamlessGrid:
      return "Seamless Grid"
    }
  }
  
  var defaultValue: Bool {
    switch self {
    case .persistLocation: return false
    case .persistInspectorState: return false
    case .showTagCountOnTiles: return false
    case .showTagUsageCounts: return false
    case .seamlessGrid: return false
    }
  }
  
  var helpText: String {
    let description = switch self {
    case .persistLocation:
      "When enabled, \(Constants.appDisplayName) will start at the last opened folder."
    case .persistInspectorState:
      "When disabled, the image inspector panel will always start out closed."
    case .showTagCountOnTiles:
      "When enabled, the number of tags on an image will be displayed on the image tile."
    case .showTagUsageCounts:
      "When enabled, tags with display with a numerical count of associated items"
    case .seamlessGrid:
      "When enabled, shows files in a seamless grid utilizing the entire window"
    }
    
    return [description, "", "Default: \(userToggle: defaultValue)"].joined(separator: "\n")
  }
  
  var codingKey: ActiveUserProfile.CodingKeys {
    switch self {
    case .persistLocation: return .persistLocation
    case .persistInspectorState: return .persistInspectorState
    case .showTagCountOnTiles: return .showTagCountOnTiles
    case .showTagUsageCounts: return .showTagUsageCounts
    case .seamlessGrid: return .seamlessGrid
    }
  }
  
  var defaultsKey: Defaults.Key<Bool> {
    Defaults.Keys.userPref(self.codingKey, self.defaultValue)
  }
}

extension String.StringInterpolation {
  mutating func appendInterpolation(userToggle: Bool) {
    appendLiteral(userToggle ? "Enabled" : "Disabled")
  }
}
