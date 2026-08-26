  // created on 4/8/25 by robinsr

  import AppKit
  import Defaults
  import Factory
  import Foundation
  import OSLog
  import System

  public final class PreferencesContainer: SharedContainer {
    public static let shared = PreferencesContainer()
    public let manager = ContainerManager()

    private let logger = CustomLogger("PreferencesContainer", level: .debug)


    /**
     * The name of the prefs file for app-wide preferences.
     *
     * Sub-divided by build scheme (debug, test, release)
     *
     * Ex: `com.foo.debug.prefs`, `com.foo.test.prefs`, `com.foo.release.prefs`
     */
    private var appPrefsKey: Factory<String> {
      self {
        let prefix = EnvContainer.shared.domainStage()
        
        return "\(prefix).prefs"
      }
    }
    
    /**
     * The name of the prefs file for the current profile
     *
     * Ex: `com.foo.debug.default`, `com.foo.test.TI5TFEHQSW`, `com.foo.release.X3AEAW7NY5`
     */
    private var userPrefsKey: Factory<String> {
      self {
        let prefix = EnvContainer.shared.domainStage()
        let profileId = self.userProfileId()
        
        return "\(prefix).\(profileId)"
      }
    }
    
    /**
     * Returns the full URL to the stage's shared prefs,
     * eg: /Users/user/Library/Preferences/com.foo.debug.prefs.plist
     */
    public var appPrefsFile: Factory<FilePath> {
      self {
        let basename = self.appPrefsKey()
        
        return AppLocation.preferences.appending("\(basename).plist")
      }
      .scope(.cached)
    }

    /**
     * Returns the `UserDefaults` suite for the current app statge (alpha, beta, release)
     */
    public var appPreferences: Factory<UserDefaults> {
      self {
        self.getSuite(key: self.appPrefsKey())
      }
      .scope(.cached)
    }

    /**
     * Returns the `UserDefaults` suite for the current user profile
     */
    public var userPreferences: Factory<UserDefaults> {
      self {
        let stage = EnvContainer.shared.stage()
        let timestamp = DateFormatter.iso8601.string(from: .now)
        
        let suite = self.getSuite(key: self.userPrefsKey())
        
        suite.set(stage.id, forKey: "tfb-stage-name")
        suite.set(timestamp, forKey: "tfb-last-opened")
        
        return suite
      }
      .scope(.cached)
    }


    //
    // MARK: - User Profile & Profile-Specific Properties
    //

    /**
     * Returns all profile **keys** listed in the stage prefs suite
     */
    var knownProfiles: Factory<[ExternalUserProfile.ID]> {
      self {
        Defaults[.knownProfiles].asArray
      }
    }

    /**
     * Returns all **profiles** listed in the stage prefs suite mapped as ``ExternalUserProfile``
     */
    var externalProfiles: Factory<[ExternalUserProfile]> {
      self {
        Defaults[.knownProfiles]
          .map { ExternalUserProfile(id: $0) }
          .collect()
      }
    }
    
    /**
     * Returns the user profile ID for the currently active user profile.
     */
    var userProfileId: Factory<ActiveUserProfile.ID> {
      self {
        let args = EnvContainer.shared.runFlags()
        
        
        /// Use profile specified by the `--profile-name=<name>` argument
        if let profileName = args.profileName {
          if let profileId = self.profileId(for: profileName) {
            self.logger.emit(.debug, "Using override profile id: \(profileId)")
            return profileId
          } else {
            self.logger.emit(.error, "No profile found for arguments \(args.string.quoted)")
          }
        }

        /// Use profile specified by the `--profile=<id>` argument
        if let profileId = args.profileId {
          if self.profileExists(id: profileId) {
            self.logger.emit(.debug, "Using override profile id: \(profileId)")
            return profileId
          } else {
            self.logger.emit(.error, "No profile found for arguments \(args.string.quoted)")
          }
        }

        /// Use the profile from UserDefaults if no other profile is specified
        let value = Defaults[.activeProfile]
        
        self.logger.emit(.debug, "Using profile id from Defaults: \(value)")
        
        return value
      }
      .onTest {
        return "default" as ActiveUserProfile.ID
      }
      .scope(.cached)
    }

    /**
     * Returns a `UserProfile` object for the user profile currently active
     */
    var userProfile: Factory<ActiveUserProfile> {
      self {
        ActiveUserProfile(suite: self.userPreferences())
      }
      .scope(.cached)
    }
    
    /**
     * Returns the active `UserProfile` wrapped in a ``UserPrefProvider`` for easy access to user preferences.
     *
     * ```swift
     * @Injected(\PreferencesContainer.prefs) var userPrefs
     *
     * var someValue: Int {
     *   userPrefs.forKey(.someIntPreference)
     * }
     * ```
     */
    var prefs: Factory<UserPrefProvider> {
      self {
        UserPrefProvider(profile: self.userProfile())
      }
      .scope(.cached)
    }

    /**
     * Ths user's pre-defined starting location. Not every user preferernce requires a property in
     * this Container, this exception exists because it's a heavily referenced pref value that is
     * needed at app start, when the other methods for getting a user pref value have not yet
     * initialized
     */
    var startingLocation: Factory<FilePath> {
      self {
        self.prefs().forKey(.profileOpenTo).filepath
      }
      .scope(.cached)
    }
    
    
    //
    // MARK: - Private Helpers
    //
    
    /// Check if the profile ID exists in the profile keys
    func profileExists(id: String) -> Bool {
      self.knownProfiles().contains(id)
    }
      
    /// Returns the profile ID for the given profile name, or nil if not found
    func profileId(for name: String) -> String? {
      let profileIds = self.knownProfiles()
      let profileNameKey = ActiveUserProfile.CodingKeys.name.rawValue
      
      for profileId in profileIds {
        if
          let profileName = self.getSuite(id: profileId).string(forKey: profileNameKey),
          profileName == name {
          return profileId
        }
      }
      
      return nil
    }

    /**
     * Helper function creates a `UserDefaults` for the given suite name (key), or returns the standard
     * suite to prevent crashes if the suite cannot be opened, was deleted, or otherwise does not exist.
     */
    func getSuite(key: String) -> UserDefaults {
      let stage = EnvContainer.shared.stage()

      self.logger.emit(.debug, "Opening UserDefaults suite for name \(key.quoted)")

      guard
        let suite = UserDefaults(suiteName: key)
      else {
        if !stage.isRelease {
          fatalError("Failed to open UserDefaults suite \(key.quoted)")
        }

        self.logger.emit(
          .critical,
          "Failed to open UserDefaults suite \(key.quoted); Returning standard UserDefaults")

        return UserDefaults.standard
      }

      return suite
    }
    
    func getSuite(id: String) -> UserDefaults {
      let prefix = EnvContainer.shared.domainStage()
      
      return getSuite(key: "\(prefix).\(id)")
    }

    /**
     * A convenience struct for accessing user preferences. Not a huge value-add, but the syntax is a bit clearer
     * and it allows for a more consistent way to access user preferences across the app.
     *
     * Usage:
     *
     * ```swift
     * PreferencesContainer.shared.prefs().forKey(.searchPerPageLimit)
     *   // the old way
     * PreferencesContainer.shared.userProfile().suite[.searchPerPageLimit]
     *
     *   // Using @Injected
     * @Injected(\PreferencesContainer.prefs) var userPrefs
     * var value: Int { userPrefs.forKey(.searchPerPageLimit) }
     *
     *   // And the old way using @Injected
     * @Injected(\PreferencesContainer.userProfile) var profile
     * var value: Int { profile.suite[.searchPerPageLimit] }
     * ```
     *
     * This was intended as a workaround for Factory's limitations with `Defaults.Key` types. The goal was to have
     * something like this:
     *
     * ```swift
     * var prefValue: Int = PreferencesContainer.shared.prefValue(for: .searchPerPageLimit)
     * ```
     *
     * But it's a generic type and I'm not sure if Factory supports generic types in the way that would allow this.
     * To be determined in the future.
     */
    struct UserPrefProvider: Sendable {
      let profile: any UserProfile

      func forKey<T>(_ key: Defaults.Key<T>) -> T {
        self.profile.suite[key]
      }

      func forKey<T>(_ key: Defaults.Key<T>, value: T) {
        self.profile.suite[key] = value
      }
    }
  }
