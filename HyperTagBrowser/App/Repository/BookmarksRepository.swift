// created on 11/26/25 by robinsr

import Combine
import GRDB

protocol BookmarksRepository {
  typealias Value = BookmarkInfoRecord
  typealias Request = ListBookmarksRequest
  
  @MainActor
  func observeBookmarks() -> AnyPublisher<[Value], any Error>
  @MainActor
  func observeBookmarks(using: Request) -> AnyPublisher<[Value], any Error>
}

struct GrdbBookmarksRepository: BookmarksRepository {
  private let dbContext = IndexerContainer.shared.dbContext()
  private let request = ListBookmarksRequest()
  
  func observeBookmarks() -> AnyPublisher<[BookmarkInfoRecord], any Error> {
    request.publisher(in: dbContext)
      .eraseToAnyPublisher()
  }
  
  func observeBookmarks(using: Request) -> AnyPublisher<[Value], any Error> {
    return request
      .publisher(in: dbContext)
      .eraseToAnyPublisher()
  }
}
