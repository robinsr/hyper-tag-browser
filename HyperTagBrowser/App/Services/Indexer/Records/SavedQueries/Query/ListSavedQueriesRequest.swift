// created on 5/25/25 by robinsr

import GRDB
import GRDBQuery


/**
 * Queryable for `SavedQueryRecord`
 */
struct ListSavedQueriesRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: [SavedQueryRecord] { [] }
  
  var limit: Int = 10
  
  func fetch(_ db: GRDB.Database) throws -> [SavedQueryRecord] {
    let request = SavedQueryRecord.all()
      .order(SavedQueryRecord.Columns.createdAt.desc)
      .limit(limit)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
