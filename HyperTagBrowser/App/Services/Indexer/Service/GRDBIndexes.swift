// created on 10/22/24 by robinsr

import Defaults
import GRDB
import Factory
import Foundation
import CustomDump
import UniformTypeIdentifiers
import System


extension GRDBIndexService: IndexAccess {

  private typealias IndxCols = IndexRecord.Columns
  private typealias IndxKeys = IndexRecord.CodingKeys
  private typealias InfoCols = IndexInfoRecord.CodingKeys
  private typealias Selections = IndexRecord.Selections
  private typealias Aliases = IndexRecord.TableAliases
  private typealias TagCol = TagRecord.Columns
  private typealias TagItemCol = IndexTagRecord.Columns
  
    // MARK: - Exists IndexRecords
  
  func indexExists(withPath path: FilePath) throws -> Bool {
    try dbReader.read { db in
      try IndexRecord.all().withPath(path).fetchCount(db) > 0
    }
  }
  
  
    // MARK: - Query IndexRecords (get IndexRecord)
  
  func getIndex(withId id: ContentId) throws -> IndexRecord? {
    try dbReader.read { db in
      try IndexRecord
        .select(IndexRecord.allColumns)
        .filter(key: id)
        .fetchOne(db)
    }
  }
  
  func getIndex(withPath path: FilePath) throws -> IndexRecord? {
    try dbReader.read { db in
      try IndexRecord.all().withPath(path).fetchOne(db)
    }
  }
  
  func getIndexes(matching params: IndxRequestParams) throws -> [IndexRecord] {
    try dbReader.read { db in
      try IndexRecord
        .all()
        .applyingParams(params)
        .limit(params.limit)
        .order(params.sqlOrdering)
        .fetchAll(db)
    }
  }
  
  func getIndexIds(matching params: IndxRequestParams) throws -> [ContentId] {
    try dbReader.read { db in
      try IndexRecord
        .select(IndxCols.id)
        .applyingParams(params)
        .asRequest(of: ContentId.self)
        .fetchAll(db)
    }
  }
  

  private func getIndexes(withIds ids: [ContentId]) throws -> [IndexRecord] {
    try dbReader.read { db in
      try IndexRecord.filter(keys: ids).fetchAll(db)
    }
  }
  
  @available(*, deprecated, message: "Unused as of 2025-11-24")
  private func getIndexes(withIds ids: [ContentId], conformingTo uttype: UTType) throws -> [IndexRecord] {
    try dbReader.read { db in
      try IndexRecord
        .filter(keys: ids)
        .filter(IndxCols.type == uttype.identifier)
        .fetchAll(db)
    }
  }
  
  @available(*, deprecated, message: "Unused as of 2025-11-24")
  private func getIndexes(under url: URL) throws -> [IndexRecord] {
    guard url.isDirectory else {
      throw IndexerServiceError.InvalidParameter("URL must be a directory; got \(url.filepath)")
    }
    
    return try dbReader.read { db in
      try IndexRecord
        .filter(IndxCols.location.like(url.filepath.string + "%"))
        .fetchAll(db)
    }
  }
  
  @available(*, deprecated, message: "Unused as of 2025-11-24")
  private func getIndexes(under url: URL, conformingTo uttype: UTType) throws -> [IndexRecord] {
    guard url.isDirectory else {
      throw IndexerServiceError.InvalidParameter("URL must be a directory; got \(url.filepath)")
    }
    
    return try dbReader.read { db in
      try IndexRecord
        .filter(IndxCols.location.like(url.filepath.string + "%"))
        .filter(IndxCols.type == uttype.identifier)
        .fetchAll(db)
    }
  }
  
    // MARK: - Query IndexRecords (get IndexInfoRecord)
  
  func getContentItem(withId cid: ContentId) throws -> IndexInfoRecord? {
    try getContentItems(withId: [cid]).first
  }
  
  func getContentItem(atPath path: FilePath) throws -> IndexInfoRecord? {
    try dbReader.read { db in
      try IndexInfoRecord.fetch(at: path).fetchOne(db)
    }
  }
  
  func getContentItems(withId ids: [ContentId]) throws -> [IndexInfoRecord] {
    try dbReader.read { db in
      try IndexInfoRecord.fetchRecords(ids: ids).fetchAll(db)
    }
  }

  func getContentItems(inFolder path: FilePath) throws -> [IndexInfoRecord] {
    try dbReader.read { db in
      try IndexInfoRecord.fetchRecords(matching: .init(root: path)).fetchAll(db)
    }
  }
  
  func getContentItems(matching params: IndxRequestParams) async throws -> [IndexInfoRecord] {
    try await dbReader.read { db in
      try IndexInfoRecord.fetchRecords(matching: params)
        .limit(params.limit, offset: params.offset)
        .fetchAll(db)
    }
  }
  
    // MARK: - Query IndexRecords (get FilePath)
  
  func getLocations() throws -> [FilePath] {
    try dbReader.read { db in
      try IndexRecord
        .distinctLocations()
        .fetchAll(db)
    }
  }
  
    // MARK: - Update IndexRecords
  
  func updateIndexes(with patch: IndexRecord.Update) throws -> Int {
//    if case .thumbnail(let scope, let config) = patch {
//      return try updateThumbnails(of: getIndexes(withIds: scope.ids), using: config)
//    }

    if case .location(let ids, let folder) = patch {
      let tasks = try moveIndexes(getIndexes(withIds: ids), to: folder)
      
      let completed = tasks.filter { $0.taskState == .completed }
      let errored = tasks.filter{ $0.taskState.isFailed }
      
      if !errored.isEmpty {
        let errorMessages = errored.map(\.failureMessage).joined(separator: "\n")
        throw IndexerServiceError.OperationFailed(errorMessages)
      }
      
      return completed.count
    }
    
    if case .name(let id, let name) = patch {
      guard let index = try getIndex(withId: id) else {
        throw IndexerServiceError.InvalidParameter("No index found with id \(id)")
      }
      
      let result = try renameIndex(index, to: name)
      
      return result.taskState.isFailed ? 0 : 1
    }
    
    return try dbWriter.write { db in
      try IndexRecord.all().filter(ids: patch.keys).updateAll(db, [patch.assignment])
    }
  }
  
  func syncIndexes(with patch: IndexRecord.Update) throws -> [IndexRecord] {
    try dbWriter.write { db in
      try IndexRecord.all()
        .filter(ids: patch.keys)
        .updateAndFetchAll(db, [patch.assignment])
    }
  }
  
  @available(*, deprecated, message: "Unused as of 2025-11-24")
  private func updateThumbnails(of records: [IndexRecord], using config: ImageDisplay) throws -> IndexerResult {
    let updates: [(IndexRecord, Data)] = records.compactMap { indx in
      guard let thumbData = config.jpegData(url: indx.url) else { return nil }
      return (indx, thumbData)
    }
    
    let results = updates.map { (indx, data) in
      logger.emit(.debug, "Updating thumbnail for \(indx.id) with size \(data.count) bytes")
      
//      do {
//        try indx.writeThumbnailData(data)
//        return 1
//      } catch {
//        logger.emit(.error, "Failed to write thumbnail for \(indx.id): \(error.localizedDescription)")
//        return 0
//      }
      return 1
    }
    
    if results.allSatisfy({ $0 == 0 }) {
      throw IndexerServiceError.OperationFailed("Failed to update all thumbnails")
    }
    
    let result = IndexerResult.success("Updated \(results.sum()) of \(records.count) thumbnails", records.count)
    logger.emit(.info, result.description)
    return result
  }
  
  func updateAndFetchIndexes(with patch: IndexRecord.Update) throws -> [IndexRecord] {
    try dbWriter.write { db in
      try IndexRecord.all().filter(ids: patch.keys).updateAndFetchAll(db, [patch.assignment])
    }
  }
  
  private func renameIndex(_ record: IndexRecord, to name: String) throws -> RenameTask {
    let patch = IndexRecord.Update.name(of: record.id, with: name)
    
    guard let task = record.renameTask(for: patch) else {
      throw IndexerServiceError.InvalidParameter("Failed to create rename task for \(record)")
    }
    
    do {
      try task.previous.move(to: task.updated)
      return task.complete()
//    } catch LocalFileServiceError.targetFileAlreadyExists(let path) {
//      return task.fail(
    } catch {
      return task.fail(error)
    }
  }
  
  private func moveIndexes(_ records: [IndexRecord], to path: FilePath) throws -> [RenameTask] {
    let patch = IndexRecord.Update.location(of: records.ids, with: path)
    
    let tasks = records
      .compactMap { indx in
        indx.renameTask(for: patch)
      }
      .map { task in
        do {
          try task.previous.move(to: task.updated)
          return task.complete()
        } catch {
          return task.fail(error)
        }
      }
    
    return tasks
  }
  
    // MARK: - Delete Index Records (remove IndexRecord)
  
  @available(*, deprecated, message: "Unused as of 2025-11-24")
  func deleteIndex(withId cid: ContentId) throws -> Bool {
    return try dbWriter.write { db in
      guard let index = try? IndexRecord.find(db, key: cid) else {
        let problem = ModeledError.failed(to: "delete IndexRecord", fallback: "none", reason: "ContentId not found")
        
        logger.emit(.error, .modeled(problem))
        
        return false
      }
      
      return try index.delete(db)
    }
  }
  
  func deleteIndexes(withIds ids: [ContentId]) throws -> Int {
    let metadata = Container.shared.metadataService()
    
    let items = try getIndexes(withIds: ids)
    try metadata.cleanAttributes(from: items.pointers)
    
    var deleted: [ContentId] = []
    
    return try dbWriter.write { db in
      for item in items {
        if try item.delete(db) {
          deleted.append(item.id)
        }
      }
      
      logger.emit(.info, "Deleted \(deleted.count) IndexRecords of expected \("ids", qty: ids.count)")
      
      return deleted.count
    }
  }
}
