// created on 10/22/24 by robinsr

import GRDB
import Foundation
import System

extension GRDBIndexService: BookmarkAccess {
  
  func bookmarkExists(to contentId: ContentId) throws -> Bool {
    try dbReader.read { db in
      try BookmarkRecord.all().forContentId(contentId).fetchCount(db) > 0
    }
  }
  
  func getBookmark(for contentId: ContentId) throws -> BookmarkInfoRecord? {
    try dbReader.read { db in
      try BookmarkInfoRecord.forContentId(contentId).fetchOne(db)
    }
  }
  
  func getBookmark(withId id: BookmarkRecord.ID) throws -> BookmarkInfoRecord? {
    try dbReader.read { db in
      try BookmarkInfoRecord.withId(id).fetchOne(db)
    }
  }
  
  func findBookmark(withPath path: FilePath) throws -> BookmarkInfoRecord? {
    try dbReader.read { db in
      try BookmarkInfoRecord.withPath(path).fetchOne(db)
    }
  }
  
  
  func createBookmark(to contentId: ContentId) throws -> BookmarkInfoRecord {
    if let bm = try getBookmark(for: contentId) {
      return bm
    }
    
    return try dbWriter.write { db in
      let bookmark = try BookmarkRecord(contentId: contentId).inserted(db)
      
      guard let bookmarkInfo = try BookmarkInfoRecord.withId(bookmark.id).fetchOne(db) else {
        throw IndexerServiceError.DataIntegrityError("Expected bookmark info to be created for \(bookmark.id)")
      }
      
      return bookmarkInfo
    }
  }
  
  func deleteBookmark(withId bookmarkId: String) throws -> BookmarkInfoRecord? {
    guard let bookmark = try getBookmark(withId: bookmarkId) else {
      throw IndexerServiceError.IdNotFound(bookmarkId)
    }
    
    let _ = try dbWriter.write { db in
      try BookmarkRecord.all().filter(id: bookmark.id).deleteAll(db)
    }
    
    return bookmark
  }
  
  func deleteBookmarks(to contentId: ContentId) throws -> [BookmarkRecord] {
    try dbWriter.write { db in
      return try BookmarkRecord.all()
        .forContentId(contentId)
        .deleteAndFetchAll(db)
    }
  }
}
