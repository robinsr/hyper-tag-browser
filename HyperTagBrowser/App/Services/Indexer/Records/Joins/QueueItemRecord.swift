// created on 10/23/24 by robinsr

import Foundation
import UniformTypeIdentifiers
import GRDB


/**
 * TableRecord representing a content item within a Queue
 */
struct QueueItemRecord: Codable, Hashable, Identifiable {
  var id: String = String.randomIdentifier(24, prefix: "queueitem:")
  var queueId: String
  var contentId: ContentId
  var created: Date
  var completed: Bool
}

extension QueueItemRecord: TableRecord {
  static let databaseTableName = "app_workqueue_items"
}

extension QueueItemRecord: FetchableRecord, PersistableRecord {
  enum CodingKeys: String, CodingKey {
    case id, queueId, contentId, created, completed
  }
  
  enum Columns: String, ColumnExpression {
    case id, queueId, contentId, created, completed
  }
  
  static let queue = belongsTo(QueueRecord.self) // , key: "queueId", using: ForeignKey([ "id"]))
  static let content = belongsTo(IndexRecord.self) //, key: "contentId", using: ForeignKey([ "id"]))
}
