// created on 4/7/25 by robinsr

import GRDB
import GRDBQuery


/**
 Queryable for `QueueRecord`. No joins
 */
struct ListQueuesRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: [QueueRecord] { [] }
  
  var forIndexIds: [IndexRecord.ID] = []
  
  func fetch(_ db: GRDB.Database) throws -> [QueueRecord] {
    let request = QueueRecord.all()
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
