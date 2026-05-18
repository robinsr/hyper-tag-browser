// created on 5/2/25 by robinsr

import Foundation


/**
 * An immutable and persistent `UserProfile`, providing:
 *
 *   - a profile to use on app launch (when no other profile exists, or was used previously)
 *   - a fallback to switch to when the profiles are deleted
 */
struct DefaultUserProfile {
  static let id: String = "default"
  static let name: String = "Default Profile"
  static let dbURL: URL = IndexerContainer.shared.newDbURL("default")
  
  /// The default user profile, modeled as active (currently in use)
  static var active: ActiveUserProfile {
    ActiveUserProfile(id: Self.id)
  }
  
  /// The default profile, modeled as external (not currently active, but can be modified)
  static var external: ExternalUserProfile {
    ExternalUserProfile(id: Self.id)
  }
}
