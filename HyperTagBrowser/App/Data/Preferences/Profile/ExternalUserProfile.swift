// created on 5/2/25 by robinsr

import Defaults
import Foundation

/**
 * Represents a user profile that is NOT the currently active profile.
 */
struct ExternalUserProfile: UserProfile, Identifiable, Hashable, Encodable {
  let id: String
  let suiteName: String
  let suite: UserDefaults

  /**
   * Retrieves an existing profile, or creates a new one if none exists.
   */
  init(id: String = .randomIdentifier(10)) {
    self.id = id
    self.suiteName = PreferencesContainer.shared.getUserSuiteKey(id).string
    self.suite = UserDefaults(suiteName: self.suiteName)!
    self.keys = ProfileKeys(suite: self.suite, id: id)
  }

  var created: Date {
    Defaults[self.keys.created]
  }

  var name: String {
    Defaults[self.keys.name]
  }

  var openTo: URL {
    Defaults[self.keys.openTo]
  }

  var hasCustomDbFile: Bool {
    Defaults[self.keys.dbFile].isNull == false
  }

  var dbFile: URL {
    Defaults[self.keys.dbFile].isNull ? defaultDBFile : Defaults[self.keys.dbFile]
  }

  func update<T>(key: Defaults.Key<T>, value: T) {
    Defaults[key] = value
  }

  enum CodingKeys: String, CodingKey {
    case id, name, suiteName, created, openTo, dbFile
  }

  
  /**
   * The set of `Defaults.Key` keys used to access this profile's data.
   */
  let keys: ProfileKeys
  
  /**
   * A set of `Defaults.Key` keys scoped specifically for a single "external" user profile (eg not the currently active profile).
   *
   * Defining `Defaults.Key` keys here differs from the standard way described in that project's README where the keys
   * are more or less global. In the case of multiple profiles that all use the same key names, global keys would
   * write over each other, leading to data loss.
   *
   * Instead, these keys are scoped to a specific profile and are used to store profile-specific data.
   *
   * Usage:
   *
   * ```swift
   * let profile = ExternalUserProfile(id: "Zebra123")
   * Defaults[profile.keys.name] // "Zebra123"
   *
   *   // The globally-defined equivalent which only ever references the loaded profile's UserDefaults suite:
   * Defaults[.profileName] // "Current"
   * ```
   */
  struct ProfileKeys: Hashable {
    let id: Defaults.Key<String>
    let created: Defaults.Key<Date>
    let name: Defaults.Key<String>
    let openTo: Defaults.Key<URL>
    let dbFile: Defaults.Key<URL>

    init(suite: UserDefaults, id _id: String, name _name: String = "Profile") {
      self.id = Defaults.Key(
        CodingKeys.id.rawValue, suite: suite, default: { _id }
      )

      self.name = Defaults.Key(
        CodingKeys.name.rawValue, suite: suite, default: { _name }
      )

      self.created = Defaults.Key(
        CodingKeys.created.rawValue, suite: suite, default: { Date.now }
      )

      self.openTo = Defaults.Key(
        CodingKeys.openTo.rawValue, suite: suite, default: { UserLocation.desktop }
      )
      
      let defaultDatabaseName = IndexerContainer.shared.newDbURL(_id)

      self.dbFile = Defaults.Key(
        CodingKeys.dbFile.rawValue, suite: suite, default: { defaultDatabaseName }
      )
    }
  }

  
  /// Why was explicit conformance to `Encodable` needed?
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(suiteName, forKey: .suiteName)
    try container.encode(created, forKey: .created)
    try container.encode(openTo, forKey: .openTo)
    try container.encode(dbFile, forKey: .dbFile)
  }

  ///
  /// Static methods
  ///

  static func create(profileName: String) -> Self {
    let profileId = String.randomIdentifier(10)
    let profile = ExternalUserProfile(id: profileId)

    Defaults[profile.keys.id] = profileId
    Defaults[profile.keys.name] = profileName
    Defaults[profile.keys.created] = Date.now

    return profile
  }
}
