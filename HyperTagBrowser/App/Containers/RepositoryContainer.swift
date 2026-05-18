// created on 11/26/25 by robinsr

import Factory

public final class RepositoryContainer: SharedContainer {
  public static let shared = RepositoryContainer()
  
  public let manager = ContainerManager()
  private let root = EnvContainer.shared
  private let prefs = PreferencesContainer.shared
  private let logger = EnvContainer.shared.logger("RepositoryContainer")
  
  var bookmarksRepo: Factory<BookmarksRepository> {
    self { GrdbBookmarksRepository() }.scope(.singleton)
  }
  
  var tagsRepo: Factory<TagsRepository> {
    self { GrdbTagsRepository() }.scope(.singleton)
  }
}
