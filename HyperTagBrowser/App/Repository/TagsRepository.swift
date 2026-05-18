// created on 11/26/25 by robinsr

import Combine
import GRDB

protocol TagsRepository {
  typealias Value = CountedTagRecord
  typealias Request = ListCountedTagsRequest
  
  @MainActor
  func observeTags(_: TagQueryParameters) -> AnyPublisher<[Value], any Error>
  
  @MainActor
  func observeTags(using: Request) -> AnyPublisher<[Value], any Error>
}

struct GrdbTagsRepository: TagsRepository {
  private let dbContext = IndexerContainer.shared.dbContext()
  
  func observeTags(_ parameters: TagQueryParameters) -> AnyPublisher<[Value], any Error> {
    let request = Request(parameters: parameters)
    
    return request
      .publisher(in: dbContext)
      .eraseToAnyPublisher()
  }
  
  func observeTags(using request: Request) -> AnyPublisher<[Value], any Error> {
    return request
      .publisher(in: dbContext)
      .eraseToAnyPublisher()
  }
  
  func newRequest(for text: String) -> Request {
    ListCountedTagsRequest(parameters: TagQueryParameters(query: text))
  }
}

