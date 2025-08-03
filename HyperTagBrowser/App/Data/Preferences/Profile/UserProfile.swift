// created on 5/2/25 by robinsr

import AppKit
import Defaults
import Foundation


/**
 * Defines properties of a container for profile-specific user setting preferences. The data is persisted in
 * a UserDefaults suite, through which the full set of user preferences can be accessed, with the most pertinent
 * properties exposed directly through this protocol.
 *
 * As well as allowing different implementations of user profiles (eg, different storage backends), this protocol
 * is primarily used to enable using the `Defaults` library, which treats all user preferences as globally scoped
 * `Default.Key` objects. The convenience is maintained, but requires two different implementations of UserProfile:
 *
 * - ``ActiveUserProfile``   - Provides the full set of defined preferences, referencable anywhere by the easier
 *                             `Defaults[...]` syntax, and as view bindings with `@Default(...)`, which is fire. Using
 *                             Defaults' APIs should works regardless of whether the preference is a profile-specific
 *                             one or a global one, which is fire.
 * - ``ExternalUserProfile`` - Provides a minimal set of properties that can be used to access the user profile. This
 *                             makes it possible to still set some values from the current profile (such updating the
 *                             name, the database file, etc) without having to switch to that profile first.
 */
protocol UserProfile: Identifiable {
  var suite: UserDefaults { get }
  var suiteName: String { get }
  var id: String { get }
  var name: String { get }
  var openTo: URL { get }
  var hasCustomDbFile: Bool { get }
  var dbFile: URL { get }
  var defaultDBFile: URL { get }
}

typealias AnyUserProfile = any UserProfile



/**
 * Some default values for all UserProfile implementations. Is it common to use this pattern to provide default
 * values for properties that are not set in the initializer.
 */
extension UserProfile {
  
    /// The default database file for this profile.
  var defaultDBFile: URL {
    IndexerContainer.shared.newDbURL(id)
  }
  
    /// The location of the properties file for this profile.
  var prefsPath: URL {
    AppLocation.preferences.appending("\(self.suiteName).plist").fileURL
  }
  
  /**
   * Opens a new instance of the app with this profile's settings.
   */
  func launchProfile() {
    // Launches the profiles in a new instance of the app
    
    let config = NSWorkspace.OpenConfiguration()
    config.activates = true
    config.arguments = ["--profile", self.id]
    config.environment = ProcessInfo.processInfo.environment
    
    let url = URL(fileURLWithPath: Bundle.main.bundlePath)
    
    NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
      if let error = error {
        print("Error launching application: \(error)")
      } else {
        print("Application launched successfully")
      }
    }
  }
}
