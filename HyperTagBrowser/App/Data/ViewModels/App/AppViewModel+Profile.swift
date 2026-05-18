// created on 11/24/25 by robinsr

import Defaults
import Factory
import Foundation


extension AppViewModel {
  
    // MARK: - Profile Actions IMPL

  func doCreateProfile(named name: String) {
    let profile = ExternalUserProfile.create(profileName: name)

    Defaults[.knownProfiles].insert(profile.id)

    messages.send(ok: "Created new profile '\(name)' (\(profile.id))")
  }
  
  func doDeleteProfile(_ profileId: ExternalUserProfile.ID, dataRetention: DataRetentionOption = .preserve) {
    let profile = ExternalUserProfile(id: profileId)
    let spotlight = Container.shared.spotlightService()

    let removeProfileTask = DispatchWorkItem {
      // Remove all keys from UserDefaults suite
      profile.suite.removeAll()
      // Remove profileId from list of profiles
      Defaults[.knownProfiles].remove(profileId)
    }
    
    let fileservice = Container.shared.fileService()

    let removeProfileDataTask = DispatchWorkItem { [self] in
      do {
        // Move this profile's database file to trash
        _ = try fileservice.moveToTrash(profile.dbFile.filepath)
        // Move this profile's plist to trash
        _ = try fileservice.moveToTrash(profile.prefsPath.filepath)

        Task {
          // Clean up this profile's search index
          try await spotlight.deleteAllItems()
        }
      } catch {
        messages.send(ErrorMsg("Error deleting profile data", error))
      }
    }

    var taskTail: DispatchWorkItem = removeProfileTask

    if dataRetention == .discard {
      taskTail = taskTail.chainTask(removeProfileDataTask)
    }

    let deletingActiveProfile = currentProfile.id == profile.id

    if deletingActiveProfile {
      logger.emit(
        .info,
        "Deleting currently active profile (\(profile.name.quoted)); Will reset with default profile"
      )

      taskTail = taskTail.chainTask{
        // Set the active profile to the default profile
        self.doSetActiveProfile(id: DefaultUserProfile.id)
      }
    }
    
    var resultMessage: String {
      switch dataRetention {
        case .discard: return "Profile deleted and data removed"
        case .preserve: return "Profile deleted"
      }
    }

    if !deletingActiveProfile {
      taskTail = taskTail.chainTask {
        self.messages.send(ok: resultMessage)
      }
    }

    DispatchQueue.global().async(execute: removeProfileTask)
  }
  
  func doSetActiveProfile(id profileId: ExternalUserProfile.ID) {
    Defaults[.activeProfile] = profileId

    Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
      Task {
        await self.messages.send(AppMessage("App restart required to apply changes", .restart))
      }
    }
  }

}
