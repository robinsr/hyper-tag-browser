// created on 10/16/24 by robinsr

import GRDB
import GRDBQuery

/**
 A request that returns all ``BookmarkRecord``s
*/
struct ListBookmarksRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: [BookmarkItem] { [] }

  func fetch(_ db: Database) throws -> [BookmarkItem] {
    let request = BookmarkRecord
      .all()
      .including(required: BookmarkRecord.content.forKey("content"))
      .asRequest(of: BookmarkInfoRecord.self)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
