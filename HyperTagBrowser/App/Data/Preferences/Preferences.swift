// created on 9/20/24 by robinsr

import AppKit
import Defaults
import Factory
import Foundation
import SwiftUI


/**
 * Shared Preferences
 *
 * Not to be confused with a user's chosen setting preferences (which are also backed by `Defaults`),
 * rather these are more like global application settings that are shared across all user profiles.
 */
extension Defaults.Keys {
  static let profileKeys            = prefKey("profileKeys", Set<String>([DefaultUserProfile.id]))
  static let activeProfile          = prefKey("activeProfile", DefaultUserProfile.id)
  @available(*, deprecated, message: "not used (except for debug purposes) as of 2025-05-27")
  static let photoGridItemInset     = prefKey("photoGridTileInset", Constants.defaultTileInset)
  static let photoGridHSpace        = prefKey("photoGridHSpace", Constants.defaultTileSpacing)
  static let photoGridVSpace        = prefKey("photoGridVSpace", Constants.defaultTileSpacing)
  static let inspectorPanels        = prefKey("openInspectorPanels", InspectorPanelState.defaults)
  
  static let statusBarIdleOpacity   = prefKey("statusBarIdleOpacity", 0.8)
  static let statusBarActiveOpacity = prefKey("statusBarActiveOpacity", 1.0)
}


/**
 * Profile-specific Preferences - the storage for a user's chosen preferences
 *
 * Accessing the underlying values can be done as a subscript on the Defaults global
 */
extension Defaults.Keys {
  static let profileId             = userPref(.id, DefaultUserProfile.id)
  static let profileName           = userPref(.name, DefaultUserProfile.name)
  static let profileDbFile         = userPref(.dbFile, SystemLocation.null)
  static let profileCreated        = userPref(.created, Date.now)
  static let profileOpenTo         = UserFolderPrefs.startLocation.defaultsKey
  
  static let searchPerPageLimit    = userPref(.searchPerPage, Int(50))
  static let photoGridItemLimit    = UserSelectPrefs<Int>.photoGridItemLimit.defaultsKey
  static let recursive             = userPref(.recursive, false)
  static let persistLocation       = UserToggles.persistLocation.defaultsKey
  static let persistInspectorState = UserToggles.persistInspectorState.defaultsKey
  static let showTagCountOnTiles   = UserToggles.showTagCountOnTiles.defaultsKey
  static let thumbnailQuality      = UserSelectPrefs<ThumbnailQuality>.thumbnailQuality.defaultsKey
  //static let imageBuffFactor       = UserSelectPrefs<ImageBuffingFactor>.imageBuffFactor.defaultValue
  static let imageBuffFactor       = userPref(.imageBuffFactor, ImageBuffingFactor.defaultValue)
  static let sidebarPosition       = UserSelectPrefs<SidebarChirality>.sidebarPosition.defaultsKey
  static let listEditorSuggestions = UserSelectPrefs<Int>.listEditorSuggestions.defaultsKey
  static let searchMethod          = UserSelectPrefs<SearchMethod>.searchMethod.defaultsKey
  
  static let devFlags              = userPref(.devFlags, DevFlags.appDefaults)
  static let debugQueryables       = userPref(.tableFlags, Set<QueryableDevFlags>())
  static let gridTileSize          = userPref(.gridTileSize, Constants.defaultTileSize)
  static let dominantImgColor      = userPref(.dominantImgColor, Color.clear)
  static let backgroundColor       = userPref(.backgroundColor, Color.lightModeBackgroundColor)
  static let backgroundOpacity     = userPref(.backgroundOpacity, 30.0)
  static let preferredScheme       = UserSelectPrefs<ColorSchemePreference>.preferredScheme.defaultsKey
}

extension UserDefaults : @unchecked @retroactive Sendable {}


extension Defaults.Keys {
  static let userSuite: UserDefaults = resolve(\PreferencesContainer.userSuite)
  static let stageSuite: UserDefaults = resolve(\PreferencesContainer.stageSuite)
  
  /**
   * Returns a Defaults.Key for a preference modeled in `UserProfile`
   */
  static func userPref<T>(_ key: ActiveUserProfile.CodingKeys, _ value: T) -> Defaults.Key<T> {
    Defaults.Key<T>(key.rawValue, default: value, suite: userSuite)
  }
  
  /**
   * Returns a Defaults.Key for a preference modeled in `UserProfile`
   */
  static func userPref<T>(_ key: ActiveUserProfile.CodingKeys, _ getter: () -> T) -> Defaults.Key<T> {
    Defaults.Key<T>(key.rawValue, default: getter(), suite: userSuite)
  }
  
  /**
   * Returns a Defaults.Key with the given key and defaulting value
   */
  static func prefKey<T>(_ key: String, _ value: T) -> Defaults.Key<T> {
    Defaults.Key<T>("tfb-\(key)", default: value, suite: stageSuite)
  }
  
  /**
   * Returns a Defaults.Key with the given key and defaulting value
   */
  static func prefKey<T>(_ key: String, _ getter: () -> T) -> Defaults.Key<T> {
    Defaults.Key<T>("tfb-\(key)", default: getter(), suite: stageSuite)
  }
}
