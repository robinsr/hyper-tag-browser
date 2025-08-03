// created on 10/16/24 by robinsr

import GRDB
import Foundation
import System


/**
 * Represents a bookmark record for a file or folder.
 */
struct BookmarkRecord: Codable, Hashable, Identifiable {
  var id: String = String.randomIdentifier(24, prefix: "bookmark:")
  var contentId: ContentId
  var created: Date = Date.now
}

extension BookmarkRecord: TableRecord {
  static let databaseTableName = "app_bookmarks"
}

extension BookmarkRecord: FetchableRecord, PersistableRecord {
  enum CodingKeys: String, CodingKey {
    case id, created, contentId
  }
  
  enum Columns: String, ColumnExpression {
    case id, created, contentId
  }
  
  static let content = belongsTo(IndexRecord.self)
}

extension DerivableRequest<BookmarkRecord> {
  private typealias Books = BookmarkRecord
  private typealias Cols = BookmarkRecord.Columns
  private typealias InfoCols = BookmarkInfoRecord.CodingKeys
    

  func joiningContent() -> Self {
    including(required: Books.content.forKey("content"))
  }
  
  func withId(_ id: String) -> Self {
    filter(Cols.id == id)
  }
  
  func forContent(_ content: IndexRecord) -> Self {
    filter(Cols.contentId == content.id)
  }
  
  func forContentId(_ contentId: ContentId) -> Self {
    filter(Cols.contentId == contentId)
  }
}

