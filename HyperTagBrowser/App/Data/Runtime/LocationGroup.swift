// created on 11/26/25 by robinsr

import Factory
import Foundation

struct LocationGroup: Identifiable, Hashable {
  var id: UUID = UUID()
  var name: String
  var items: [IdentifiedURL]
  
  init(name: String, urls: [URL]) {
    self.name = name
    self.items = urls.map { IdentifiedURL(url: $0) }
  }
  
  struct IdentifiedURL: Identifiable, Hashable {
    var id: UUID = UUID()
    var url: URL
  }
  
  @MainActor private static var fs = Container.shared.fileService()
  @MainActor private static var loginUser = EnvContainer.shared.userName()
  
  static func named(_ name: String, _ urls: [URL?]) -> Self {
    LocationGroup(name: name, urls: urls.compactMap{ $0 })
  }
  
  static func named(_ name: String, _ url: URL?) -> Self {
    LocationGroup(name: name, urls: [url].compactMap{ $0 })
  }
  
  static func parent(of url: URL) -> Self {
    LocationGroup(name: "Parent Folder", urls: [url.deletingLastPathComponent()])
  }
  
  @MainActor static func contents(of url: URL) -> Self {
    LocationGroup(name: "Subfolders", urls: fs.subfolders(of: url))
  }
  
  @MainActor static func adjacent(to url: URL) -> Self {
    LocationGroup(name: "Adjacent Folders", urls: fs.adjacent(to: url))
  }
  
  @MainActor static let user: Self = .named("\(loginUser)'s Folders", [
    UserLocation.home,
    UserLocation.desktop,
    UserLocation.documentsURL,
    UserLocation.downloadsURL,
  ])
}
