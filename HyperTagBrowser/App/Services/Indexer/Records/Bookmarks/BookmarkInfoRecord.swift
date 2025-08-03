// created on 6/9/25 by robinsr

import GRDB
import System


/**
 * Joins ``BookmarkRecord`` with ``IndexRecord``
 */
struct BookmarkInfoRecord: Codable, FetchableRecord {
  var bookmark: BookmarkRecord
  var content: IndexRecord
  
  var id: String { bookmark.id }
  var name: String { content.name }
  var filepath: FilePath { content.filepath }
  var location: FilePath { content.location }
  
  enum CodingKeys: String, CodingKey {
    case bookmark, content
  }
}


extension BookmarkInfoRecord {
  private typealias Books = BookmarkRecord
  private typealias Cols = BookmarkRecord.Columns
  private typealias InfoCols = BookmarkInfoRecord.CodingKeys
  
  static func withId(_ id: BookmarkRecord.ID) -> QueryInterfaceRequest<BookmarkInfoRecord> {
    BookmarkRecord
      .all()
      .joiningContent()
      .withId(id)
      .asRequest(of: BookmarkInfoRecord.self)
  }
  
  static func forContentId(_ contentId: ContentId) -> QueryInterfaceRequest<BookmarkInfoRecord> {
    BookmarkRecord
      .all()
      .joiningContent()
      .forContentId(contentId)
      .asRequest(of: BookmarkInfoRecord.self)
  }
  
  static func withPath(_ path: FilePath) -> QueryInterfaceRequest<BookmarkInfoRecord> {
    BookmarkRecord
      .all()
      .joiningContent()
      .filter(IndexRecord.Selections.fileURL == path)
      .asRequest(of: BookmarkInfoRecord.self)
  }
}


typealias BookmarkItem = BookmarkInfoRecord
