// created on 1/25/25 by robinsr

import Foundation
import Defaults


/**
 A `UserPrefSet` where the preference value is a filesystem URL
 */
enum UserFolderPrefs: String, Defaults.Serializable, CaseIterable, UserPrefSet {
  case startLocation
  
  var id: String { rawValue }
  
  var label: String {
    switch self {
    case .startLocation:
      return "Start Location"
    }
  }
  
  var defaultValue: URL {
    switch self {
    case .startLocation: return UserLocation.desktop
    }
  }
  
  var allowedTypes: AllowedFileTypes {
    switch self {
    case .startLocation: return .folders
    }
  }
  
  var helpText: String {
    switch self {
    case .startLocation:
      return "The folder \(Constants.appname) will open to by default."
    }
  }
  
  var codingKey: ActiveUserProfile.CodingKeys {
    switch self {
      case .startLocation: return .openTo
    }
  }
  
  var defaultsKey: Defaults.Key<URL> {
    Defaults.Keys.userPref(self.codingKey, self.defaultValue)
  }
}
