// created on 10/22/24 by robinsr

import GRDB

extension GRDBIndexService : ContentQueueAssociation {
  
  func createQueue(named name: String) throws -> QueueRecord {
    try dbWriter.write { db in
      let newQueue = QueueRecord(name: name, created: .now)
      return try newQueue.insertAndFetch(db)
    }
  }
  
  
  func insertIntoQueue(queueId: String, content: [ContentId]) throws {
    let newQueueItems = content.map {
      QueueItemRecord(
        queueId: queueId,
        contentId: $0,
        created: .now,
        completed: false)
    }
    
    try dbWriter.write { db in
      for queueItem in newQueueItems {
        try queueItem.insert(db)
      }
    }
  }
  
  func insertIntoQueue(queueId: String, content: ContentId) throws {
    try self.insertIntoQueue(queueId: queueId, content: [content])
  }
}
