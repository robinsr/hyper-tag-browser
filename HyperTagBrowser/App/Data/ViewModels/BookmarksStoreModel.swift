// created on 11/27/25 by robinsr

import Factory
import SwiftUI

typealias BookmarkItem = BookmarkInfoRecord

@MainActor
@Observable
final class BookmarksStoreModel {
  @ObservationIgnored private let bookmarksRepo = RepositoryContainer.shared.bookmarksRepo()
  @ObservationIgnored private var bookmarksCancellable: AnyCancellable?
  //private var currentBookmarkRequest: ListBookmarksRequest?
  
  var bookmarks: [BookmarkItem] = []
  
  init() {
    bookmarksCancellable = bookmarksRepo.observeBookmarks()
      .removeDuplicates()
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] items in
          self?.bookmarks = items
        }
      )
  }
}
