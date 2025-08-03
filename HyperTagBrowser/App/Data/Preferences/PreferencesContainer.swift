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

    private var root: EnvContainer {
      EnvContainer.shared
    }

    let logger = EnvContainer.shared.logger("PreferencesContainer")
  }

  extension PreferencesContainer {

    /**
     Returns keys such as: `com.foo.alpha.prefs`, `com.foo.beta.prefs`, `com.foo.release.prefs`
     */
    var stagePrefsKey: Factory<DotPath> {
      self {
        let bundleId = self.root.bundleIdentider()
        let stageName = self.root.stageName()

        return [bundleId, stageName, "prefs"].asDotPath
      }
    }

    /**
     * Returns a suite key for the given user profile, such as: `com.foo.alpha.XYZXYZ`, `com.foo.beta.XYZXYZ`, `com.foo.XYZXYZ`
     */
    var getUserSuiteKey: ParameterFactory<String, DotPath> {
      self { profileId in
        let bundleId = self.root.bundleIdentider()
        let stageName = self.root.stageName()

        return [bundleId, stageName, profileId].asDotPath
      }
    }

    /**
     * Returns the profile ID for the given profile name, or nil if not found
     */
    var getUserProfileId: ParameterFactory<String, String?> {
      self {
        self.getProfileIdFor(name: $0)
      }
    }

    /**
     * Returns the default UserDefaults suite name for the current user profile
     */
    var userSuiteKey: Factory<DotPath> {
      self {
        let profileId = self.userProfileId()

        return self.getUserSuiteKey(profileId)
      }
    }

    /**
     * Returns the full URL to the stage's shared prefs,
     * eg: /Users/user/Library/Preferences/com.foo.alpha.prefs.plist
     */
    var stagePrefsURL: Factory<URL> {
      self {
        let filename = self.stagePrefsKey().appending("plist").string

        return AppLocation.preferences.appending(filename).fileURL
      }
      .scope(.cached)
    }

    /**
     * Returns the `UserDefaults` suite for the current app statge (alpha, beta, release)
     */
    var stageSuite: Factory<UserDefaults> {
      self {
        self.getSuite(key: self.stagePrefsKey().string)
      }
      .scope(.cached)
    }

    /**
     * Returns the `UserDefaults` suite for the current user profile
     */
    var userSuite: Factory<UserDefaults> {
      self {
        self.getSuite(key: self.userSuiteKey().string)
      }
      .scope(.cached)
    }

    /**
     * Returns the `UserDefaults` suite for the default user profile.
     */
    var defaultUserSuite: Factory<UserDefaults> {
      self {
        self.getSuite(key: self.getUserSuiteKey(DefaultUserProfile.id).string)
      }
      .scope(.cached)
    }

    //
    // MARK: - User Profile & Profile-Specific Properties
    //


    /**
     * Returns all profile **keys** listed in the stage prefs suite
     */
    var profileKeys: Factory<[ExternalUserProfile.ID]> {
      self {
        Defaults[.profileKeys].asArray
      }
    }

    /**
     * Returns all **profiles** listed in the stage prefs suite mapped as ``ExternalUserProfile``
     */
    var externalProfiles: Factory<[ExternalUserProfile]> {
      self {
        Defaults[.profileKeys]
          .map { ExternalUserProfile(id: $0) }
          .collect()
      }
    }
    
    /**
     * Returns the user profile ID for the currently active user profile.
     */
    var userProfileId: Factory<ActiveUserProfile.ID> {
      self {
        let args = self.root.runFlags()
        
        
        /// Find and use profile based on the `--profile-name=$NAME` argument
        if let profileName = args.profileName {
          if let profileId = self.getProfileIdFor(name: profileName) {
            self.logger.emit(.debug, "Using override profile id: \(profileId)")
            return profileId
          } else {
            self.logger.emit(.error, "No profile found for arguments \(args.string.quoted)")
          }
        }

        /// Use profile based on `--profile=$NAME` argument if provided
        if let profileId = args.profileId {
          if self.hasProfileFor(id: profileId) {
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
      .scope(.cached)
    }

    /**
     * Returns a `UserProfile` object for the user profile currently active
     */
    var userProfile: Factory<ActiveUserProfile> {
      self {
        ActiveUserProfile(suite: self.userSuite())
      }
      .scope(.cached)
    }

    /**
     * Returns the name of the user profile currently active
     */
    var userProfileName: Factory<String> {
      self {
        self.userProfile().name
      }
    }
    
    /**
     * Returns the active `UserProfile` wrapped in a ``UserPrefProvider`` for easy access to user preferences.
     *
     * ```swift
     * @Injected(\PreferencesContainer.userPreferences) var userPrefs
     *
     * var someValue: Int {
     *   userPrefs.forKey(.someIntPreference)
     * }
     * ```
     */
    var userPreferences: Factory<UserPrefProvider> {
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
        self.userPreferences().forKey(.profileOpenTo).filepath
      }
      .scope(.cached)
    }
    
    
    //
    // MARK: - Private Helpers
    ///
    
    
      /// Check if the profile ID exists in the profile keys
    private func hasProfileFor(id: String) -> Bool {
      self.profileKeys().contains(id)
    }
      
      /// Returns the profile ID for the given profile name, or nil if not found
    private func getProfileIdFor(name: String) -> String? {
      let profilekeys = self.profileKeys()
      let profileNameKey = ActiveUserProfile.CodingKeys.name.rawValue
      
      for key in profilekeys {
        let suiteName = self.getUserSuiteKey(key).string
        let suite = self.getSuite(key: suiteName)
        
        guard let name = suite.string(forKey: profileNameKey) else { continue }
        
        if name == name {
          return key
        }
      }
      
      return nil
    }

    /**
     * Helper function creates a `UserDefaults` for the given suite name (key), or returns the standard
     * suite to prevent crashes if the suite cannot be opened, was deleted, or otherwise does not exist.
     */
    private func getSuite(key: String) -> UserDefaults {
      let stage = self.root.stage()

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

    /**
     * A convenience struct for accessing user preferences. Not a huge value-add, but the syntax is a bit clearer
     * and it allows for a more consistent way to access user preferences across the app.
     *
     * Usage:
     *
     * ```swift
     * PreferencesContainer.shared.userPreferences().forKey(.searchPerPageLimit)
     *   // the old way
     * PreferencesContainer.shared.userProfile().suite[.searchPerPageLimit]
     *
     *   // Using @Injected
     * @Injected(\PreferencesContainer.userPreferences) var userPrefs
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
    struct UserPrefProvider {
      let profile: any UserProfile

      func forKey<T>(_ key: Defaults.Key<T>) -> T {
        self.profile.suite[key]
      }

      func forKey<T>(_ key: Defaults.Key<T>, value: T) {
        self.profile.suite[key] = value
      }
    }
  }
