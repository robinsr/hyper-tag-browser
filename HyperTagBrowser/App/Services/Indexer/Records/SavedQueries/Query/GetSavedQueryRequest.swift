// created on 5/25/25 by robinsr

import GRDB
import GRDBQuery


/**
 * Queryable for `SavedQueryRecord` fetched by ID.
 */
struct GetSavedQueriesRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: SavedQueryRecord? { nil }
  
  var id: SavedQueryRecord.ID?
  
  func fetch(_ db: GRDB.Database) throws -> SavedQueryRecord? {
    guard let id = id else {
      return nil
    }
    
    let request = SavedQueryRecord.all().withId(id)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchOne(db)
      }
    }
  }
}
