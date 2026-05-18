// created on 4/7/25 by robinsr

import GRDB


/**
 * Joins ``QueueRecord`` with ``IndexRecord``
 */
struct QueueIndexesRecord: FetchableRecord, Identifiable, Equatable, Hashable, Codable {
  var queue: QueueRecord
  var indexes: [IndexRecord]
  
  var id: String {
    queue.id
  }
  
  enum CodingKeys: String, CodingKey {
    case queue, indexes
  }
}

extension QueueIndexesRecord: Filterable {
  var asFilter: FilteringTag {
    queue.asFilter
  }
}
