// created on 5/26/25 by robinsr

import GRDB

/**
 * Defines some schema-related things...
 *
 * This was previously stuffed into the main service class as private properties, but
 * my sense is that these should be more visible and accessible, naming issues aside.
 */
struct SchemaConfiguration {
  static let tables: [any TableRecord.Type] = [
    BookmarkRecord.self,
    IndexRecord.self,
    IndexTagRecord.self,
    IndexTagValueRecord.self,
    IndexTagCountRecord.self,
    QueueItemRecord.self,
    QueueRecord.self,
    TagRecord.self,
    TagstringRecord.self,
  ]
  
  static let views: [any DatabaseView.Type] = [
    IndexTagValueRecord.self,
    IndexTagCountRecord.self,
    TagstringRecord.self,
  ]
  
  static var tableNames: [String] {
    tables.map { $0.databaseTableName }
  }
  
  static var viewNames: [String] {
    views.map { $0.databaseTableName }
  }
}
