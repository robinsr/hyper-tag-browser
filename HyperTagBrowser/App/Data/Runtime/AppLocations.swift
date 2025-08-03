// created on 2/4/25 by robinsr

import Foundation
import System


struct UserLocation {
  static let home = FileManager.default.homeDirectoryForCurrentUser
  
  static let homePath = FileManager.default.homeDirectoryForCurrentUser.filepath
  
  static let desktop = FileManager.default.homeDirectoryForCurrentUser
    .appending(path: "Desktop", directoryHint: .isDirectory)
  
  static let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].filepath
}


struct SystemLocation {
  static let tmpDir: FilePath = FileManager.default.temporaryDirectory.filepath

  static let appSupport: FilePath = URL.applicationSupportDirectory.filepath
  
  static let root = FilePath("/")
  
  static let volumes = FilePath("/Volumes")
  
  /// By self-convention, this URL value is considered to be equivalent to `nil`.
  static let null = URL.null
}


struct AppLocation {
  static let appSupport: FilePath = SystemLocation.appSupport.appending(Constants.appname)
  
  static let preferences: FilePath = UserLocation.homePath.appending("Library/Preferences")
  
  static let caches: FilePath = UserLocation.caches.appending(Constants.appname)
}
