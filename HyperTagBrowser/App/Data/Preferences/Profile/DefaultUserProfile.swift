// created on 5/2/25 by robinsr

import Foundation


/**
 * An immutable and non-delete-ablwe UserProfile that is used for:
 *
 *   - The profile chosen on launch if no other profile has been set in the stage's preferences
 *   - As a fallback profile in cases where the current profile is deleted while active
 */
struct DefaultUserProfile {
  static let id: String = "default"
  static let name: String = "Default Profile"
  static let dbURL: URL = IndexerContainer.shared.newDbURL("default")
  
  static var active: ActiveUserProfile {
    ActiveUserProfile(suite: PreferencesContainer.shared.defaultUserSuite())
  }
  
  static var external: ExternalUserProfile {
    ExternalUserProfile(id: Self.id)
  }
}
