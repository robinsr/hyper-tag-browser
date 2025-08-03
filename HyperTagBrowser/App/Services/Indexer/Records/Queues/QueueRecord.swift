// created on 10/21/24 by robinsr

import CustomDump
import Foundation
import UniformTypeIdentifiers
import GRDB


struct QueueRecord: Codable, Identifiable, Filterable {
  var id: String = String.randomIdentifier(24, prefix: "queue:")
  var name: String
  var created: Date
  
  /// A value matching the `TagRecord` that links `IndexRecord` items to this queue
  var tagName: String?
  
  /**
   An associated folder, files added to the folder will be added to the queue
   */
  var folder: URL?
  
  var asFilter: FilteringTag {
    .queue(self.name)
  }
}


extension QueueRecord: TableRecord, FetchableRecord, PersistableRecord {
  static let databaseTableName = "app_workqueues"
  
  enum CodingKeys: String, CodingKey {
    case id, name, created
  }
  
  enum Columns: String, ColumnExpression {
    case id, name, created, tagName
  }
  
  /// Referes to the join table between `QueueRecord` and `IndexRecord`
  static let queueItems = hasMany(QueueItemRecord.self)
  
  /// Refers to the `IndexRecord` rows associated through the above join tabledes
  static let indexes = hasMany(
    IndexRecord.self,
    through: queueItems,
    using: QueueItemRecord.content,
    key: "contentId"
  )
  
  /// Refers to the `IndexTagRecord` rows that point to a `QueueRecord`
  static let queueTagItems = hasMany(
    IndexTagValueRecord.self,
    using: ForeignKey(["value"], to: ["tagName"])
  )
  
  static let queueTagIndexes = hasMany(
    IndexRecord.self,
    through: queueTagItems,
    using: IndexTagValueRecord.associatedContent,
    key: "contentId"
  )
  
  struct Selections {
    
       /**
        * A selector that returns a string with the name of the queue
        * in the same format as ``TagRecord/Selections/filterValue``.
        *
        * Should generate as
        *
        * ```sql
        * SELECT "queue"||"<separator>"||QueueRecord.name ...
        * ```
        *
        * Example: `"queue|myQueueName"`
        */
    static var filterValue: SQLExpression {
      DatabaseFunctions.textJoin.call(FilteringTag.separator, "queue".sqlExpression, Columns.name)
    }
  }
}
