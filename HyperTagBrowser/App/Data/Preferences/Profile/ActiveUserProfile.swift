// created on 12/16/24 by robinsr

import Defaults
import Factory
import Foundation

/**
 * Represents the singular `UserProfile` instance generally understood to be the Active one. It's loaded at
 * application launch and is used throughout the app to access user preferences. Switching profiles requires
 * deinitializing the current `ActiveUserProfile` and creating a new one with the desired `UserDefaults` suite.
 * Maybe there;s a way to make sure there can only ever be one value of ActiveUserProfile at a time? Does swift support that
 *
 * Usage:
 *
 * Getting a preference value:
 *
 * ```swift
 * let profile: ActiveUserProfile = ...
 *
 *   // Use this struct's CodingKeys
 * let widgetB = profile.suite[.showWidgetB]
 *
 *   // Or the old fashioned way
 * let widgetA = profile.suite.bool(forKey: "showWidget")
 * ```
 */
struct ActiveUserProfile: UserProfile, Identifiable, Hashable, Encodable {
  let suite: UserDefaults

  init(suite: UserDefaults) {
    self.suite = suite
  }

  var suiteName: String {
    suite.description
  }

  var id: String {
    Defaults[.profileId]
  }

  var created: Date {
    Defaults[.profileCreated]
  }

  var name: String {
    Defaults[.profileName]
  }

  var openTo: URL {
    Defaults[.profileOpenTo]
  }

  var hasCustomDbFile: Bool {
    Defaults[.profileDbFile].isNull == false
  }

  var dbFile: URL {
    Defaults[.profileDbFile].isNull ? defaultDBFile : Defaults[.profileDbFile]
  }


  /**
   * Defines the complete set of settings that a user can customize to their personal preference
   *
   * This enum also serves as a base from which to create the `Defaults.Key` key objects to read and write these
   * settings.
   */
  enum CodingKeys: String, CodingKey {
    case id
    case created
    case name
    case openTo
    case dbFile

    case backgroundColor
    case backgroundOpacity
    case devFlags
    case dominantImgColor
    case gridTileSize
    case listEditorSuggestions
    case persistInspectorState
    case persistLocation
    case photoGridItemLimit
    case preferredScheme
    case recursive
    case searchMethod
    case searchPerPage
    case showTagCountOnTiles
    case sidebarPosition
    case tableFlags
    case thumbnailQuality
    case imageBuffFactor
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(created, forKey: .created)
    try container.encode(name, forKey: .name)
    try container.encode(openTo, forKey: .openTo)
    try container.encode(dbFile, forKey: .dbFile)
  }
}



/**
 * A actor container for the `GlobalUserProfile` that represents the currently active user profile.
 */
actor UserProfileActor: UserProfile {
  nonisolated let suite: UserDefaults
  nonisolated let suiteName: String
  nonisolated let id: String
  nonisolated let name: String
  nonisolated let created: Date
  nonisolated let openTo: URL
  nonisolated let dbFile: URL
  nonisolated let hasCustomDbFile: Bool

  let profile: ActiveUserProfile

  init(suite: UserDefaults) {
    let profile = ActiveUserProfile(suite: suite)
    
    self.profile = profile
    self.suite = profile.suite
    self.suiteName = profile.suiteName
    self.id = profile.id
    self.name = profile.name
    self.created = profile.created
    self.openTo = profile.openTo
    self.dbFile = profile.dbFile
    self.hasCustomDbFile = profile.hasCustomDbFile
  }

  
  /// Required conformance by UserProfile, but there shoud never be two active profiles at the same time, therefore
  /// never two instances of this type to compare
  public static func == (lhs: UserProfileActor, rhs: UserProfileActor) -> Bool {
    return false
  }
}
