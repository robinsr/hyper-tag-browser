// created on 4/7/25 by robinsr

import GRDB


/**
 * Joins ``QueueRecord`` with ``IndexRecord``
 */
struct QueueIndexesRecord: Codable, FetchableRecord {
  var queue: QueueRecord
  var indexes: [IndexRecord]
  
  enum CodingKeys: String, CodingKey {
    case queue, indexes
  }
}
