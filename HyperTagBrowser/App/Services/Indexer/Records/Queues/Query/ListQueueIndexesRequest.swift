// created on 10/22/24 by robinsr

import GRDB
import GRDBQuery


/**
 * Queryable for ``QueueIndexesRecord`` (queue: ``QueueRecord``, items: ``QueueItemWithFilename``)
 */
struct ListQueueIndexesRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: [QueueIndexesRecord] { [] }
  
  var forIndexIds: [IndexRecord.ID] = []
  
  func fetch(_ db: GRDB.Database) throws -> [QueueIndexesRecord] {
    let request = QueueRecord
      .including(all: QueueRecord.queueTagIndexes.forKey(QueueIndexesRecord.CodingKeys.indexes))
      .asRequest(of: QueueIndexesRecord.self)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
