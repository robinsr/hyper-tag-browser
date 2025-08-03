// created on 10/22/24 by robinsr

import GRDB
import Foundation
import Factory
import System


extension GRDBIndexService : ContentIndexer {
  
  private typealias TagCol = TagRecord.Columns
  private typealias TagItemCol = IndexTagRecord.Columns
  private typealias IndexCol = IndexRecord.Columns
  
  
  func removeIndex(of pointers: [ContentPointer]) throws -> Int {
    try self.deleteIndexes(withIds: pointers.ids)
  }
  
  private func fetchIndexInfo(inTransaction db: Database, id: ContentId) throws -> IndexInfoRecord? {
    try IndexInfoRecord.info(id: id).fetchOne(db)
  }
  
  
  private func getFilenameData(for url: URL) -> [FilteringTag] {
    let nameData = FilenameData(fileURL: url)
    
    // Extract tags from filename patterns
    let filenameTags = [
      nameData.mapTo(\.inBracesValues, type: .tag),
      nameData.mapTo(\.inBracketValues, type: .creator),
    ].flatMap(\.self)
    
    return filenameTags
  }
  
  
  /// Adds a new file to the index
  ///
  /// TODO: Will this update a file (name change, tag update?)
  func createIndex(inTransaction db: Database, path: FilePath) throws -> IndexInfoRecord {
    guard let contentId = try metadata.retrieveXID(for: path.fileURL) else {
      throw IndexerServiceError.DataIntegrityError("ContentId not found for file", attributes: ["url": path.string])
    }
    
    let indx = try IndexRecord(path: path, contentId: contentId)
    let indxExists = try indx.exists(db)
    
    var indxTags: [IndexTagRecord] = []
    
    if !indxExists {
        // Do not create TagRecords from filename patterns for existing indexes
        
        // TODO: Make this configurable in the UI
      let filenameTags = getFilenameData(for: path.fileURL).asSet
      let tagRecords = try findOrCreateTags(inTransaction: db, for: filenameTags)
      
      tagRecords
        .map { $0.newAssociation(toContentId: indx.id) }
        .forEach { indxTags.append($0) }
    }
    
    do {
      try indx.insert(db, onConflict: .replace)
      try indxTags.forEach { try $0.insert(db) }
    } catch {
      throw opFailed("Failed to insert new IndexRecord", err: error)
    }
    
    guard let indxinfo = try fetchIndexInfo(inTransaction: db, id: indx.id) else {
      throw opFailed("Failed to load IndexInfoRecord for conflicting ID '\(indx.id.value)'")
    }
    return indxinfo
  }


  func createIndex(for path: FilePath) throws -> IndexInfoRecord {
    try dbWriter.write { db in
      try createIndex(inTransaction: db, path: path)
    }
  }

  
  func diffDirectoryContents(of path: FilePath, mode: ListMode) throws -> ContentPointerDiff {
    let dirContents: [ContentPointer] = fs.indexContents(at: path, mode: mode, types: .user)
    
    let query = BrowseFilters(
      root: path,
      mode: mode,
      types: [.content, .folders],
      limit: 10000,
      visibility: .any
    )
    
    let indexed: [IndexRecord] = try getIndexes(matching: query)
    
    let indexedSet: Set<FilePath> = indexed.map(\.filepath).asSet
    let listingSet: Set<FilePath> = dirContents.map { $0.contentPath }.asSet
    
    let added = listingSet.subtracting(indexedSet).compactMap { dirContents[$0] }
    let removed = indexedSet.subtracting(listingSet).compactMap { indexed[$0] }.map(\.pointer)
    let unchanged = indexedSet.intersection(listingSet).compactMap { indexed[$0] }.map(\.pointer)
    
    return (removed, added, unchanged)
  }
  
  
  /**
   * Iterates through the directory contents of `url` and insert/updates `IndexRecord`s as needed.
   *
   * TODO: Re-indexing a folder wipes out all the tags!
   */
  func indexDirectory(at path: FilePath) throws -> ContentIndexingResult {
    // let dirContents = fs.indexContents(at: url, mode: .immediate(.uncached), types: .all)

    let diff = try diffDirectoryContents(of: path, mode: .immediate(.uncached))
    
    #if DEBUG
    logger.dump(diff, label: "ContentIDs listed by fs, not indexed in SwiftData")
    #endif
    
    
    var relocated: [ContentPointer] = []
    var deleted: [ContentPointer] = []
    var created: [ContentPointer] = []
    
    try dbWriter.write { db in
      relocated = try IndexRecord.all()
        .filter(ids: diff.added.ids)
        .filter(IndexRecord.Columns.location != path)
        .updateAndFetchAll(db, [
          IndexRecord.Columns.location.set(to: path)
        ])
        .map(\.pointer)
      
      logger.emit(.info, "Relocated \("record", qty: relocated.count)")
    }
    
    try dbWriter.write { db in
      deleted = try IndexRecord.all()
        .filter(ids: diff.removed.ids)
        .filter(IndexRecord.Columns.location == path)
        .deleteAndFetchAll(db)
        .map(\.pointer)
      
      logger.emit(.info, "Deleted \("record", qty: deleted.count)")
    }
    
    try dbWriter.write { db in
      let indexedIds = try IndexRecord.all()
        .select(IndexRecord.Columns.id)
        .filter(ids: diff.added.ids)
        .asRequest(of: ContentId.self)
        .fetchAll(db)
      
      let nonExistingIds = Set(diff.added.ids).subtracting(Set(indexedIds)).asArray
      
      created = nonExistingIds
        .compactMap { id in
          diff.added.first(where: { $0.contentId == id })
        }
        .compactMap {
          if let indx = try? createIndex(inTransaction: db, path: $0.contentURL.filepath) {
            return indx.pointer
          } else {
            return nil
          }
        }
    }
    
    return ContentIndexingResult(
      removed: deleted,
      added: created + relocated,
      unchanged: diff.unchanged
    )
  }
}
