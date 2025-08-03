// created on 11/8/24 by robinsr

import GRDB
import Factory
import Foundation
import UniformTypeIdentifiers
import OSLog



struct ObservationConfig: CaseIterable {
  let name: String
  let fsStatus: IndexHistory.Status
  let indexType: UTType
  
  
  var tracking: QueryInterfaceRequest<IndexHistory> {
    IndexHistory.trackingRegion(status: fsStatus, conformingTo: indexType)
  }
  
  var query: QueryInterfaceRequest<IndexHistoryInfo> {
    IndexHistory.queryItems(status: fsStatus, conformingTo: indexType)
  }
  
  func observer() -> DatabaseRegionObservation {
    .init(tracking: self.tracking)
  }
  
  static let pendingContent = ObservationConfig(
    name: "PendingFiles",
    fsStatus: .pending,
    indexType: .content
  )
  
  static let pendingFolders = ObservationConfig(
    name: "PendingFolders",
    fsStatus: .pending,
    indexType: .folder
  )
  
  static let failedRows = ObservationConfig(
    name: "FailedTransactions",
    fsStatus: .failed,
    indexType: .content
  )
  
  static var allCases: [ObservationConfig] {
    [pendingContent, pendingFolders, failedRows]
  }
}



class ContentItemRenamedObserver {
  private let logger = EnvContainer.shared.logger("ContentItemRenamedObserver")
  
  @Injected(\IndexerContainer.dbWriter) private var db
  @Injected(\IndexerContainer.indexService) private var indexer
  @Injected(\Container.fileService) private var fs
  
  
  private var cancellables: [DatabaseCancellable] = []
  
  
  typealias History = IndexHistory
  typealias Update = IndexHistory.Update
  typealias Entry = IndexHistoryInfo
  typealias Query = QueryInterfaceRequest<IndexHistoryInfo>
  
  typealias Errors = ContentObserverError
  
  typealias ObserverHandler = (Database) throws -> Void
  typealias OnChangeFn = (Database) -> Void
  
  
  init() {}
  
  
  func startObservation() {
    self.cancellables = ObservationConfig.allCases.map { config in
      config.observer().start(in: db, named: config.name) { db in
        
        self.logger.emit(.debug, "Observer triggered for \(config.name)")
        
        let items = try config.query.fetchAll(db)
        
        self.logger.dump(items, label: "Fetched \(items.count) items for \(config.name) observation")
        
        switch (config.fsStatus, config.indexType) {
        case (.pending, .content):
          try self.processPendingFiles(items)
        case (.pending, .folder):
          try self.processPendingFolders(items)
        default:
          try self.processFailedRow(items)
        }
        
      }
    }
  }
  
  func stopObservation() {
    logger.emit(.info, "Stopping all database observers")
    
    self.cancellables.forEach { $0.cancel() }
    self.cancellables.removeAll()
  }
  
  
  func processPendingFiles(_ records: [IndexHistoryInfo]) throws {
    for info in records {
      guard let renameTask = info.transaction.renameTask(for: info.index) else {
        logError(.missingRenameTask(info))
        continue
      }
      
      if renameTask.isNoop {
        logUpdate("No-op rename task for \(info.index.url), skipping.")
        
        try postUpdate(info.transaction.synced)
        continue
      }
      
      let result = moveSingleFile(renameTask)
      
      if result.taskState.isFailed {
        try postUpdate(info.transaction.failed)
        continue
      }
      
      try postUpdate(info.transaction.synced)
    }
  }
  
  func processPendingFolders(_ folders: [IndexHistoryInfo]) throws {
    for folder in folders {
      guard let renameTask = folder.transaction.renameTask(for: folder.index) else {
        logError(.missingRenameTask(folder))
        continue
      }
      
      if renameTask.isNoop {
        logUpdate("No-op rename task for \(folder.index.url), skipping.")
        
        try postUpdate(folder.transaction.synced)
        continue
      }
      
      let result = moveSingleFile(renameTask)
      
      if result.taskState.isFailed {
        try postUpdate(folder.transaction.failed)
        continue
      }
      
      // let _ = try indexer.indexDirectory(at: folder.transaction.updatedPath)
      
      try postUpdate(folder.transaction.synced)
    }
  }
   
   
  private func processFailedRow(_ rows: [IndexHistoryInfo]) throws {
    for row in rows {
      guard let revertUpdate = row.transaction.revertUpdate else {
        logError(.unknownColumn(row))
        continue
      }
      
      do {
        let revertResult = try indexer.updateIndexes(with: revertUpdate)
        
        logger.emit(.info, "Revert result: \(json: revertResult)")
      } catch {
        logError(.unexpected("Unexpected error while reverting previous DB changes:", error))
      }
    }
  }
  
  
  func moveSingleFile(_ task: RenameTask) -> RenameTask {
    logger.emit(.info, "Processing RenameTask: \(task)")
    
    do {
      try fs.rename(task.previous, to: task.updated)
    } catch {
      let failed = task.fail(error)
      
      logError(.failedRenameTask(failed))
      
      return failed
    }
    
    return task.complete()
  }
  
  
  func postUpdate(_ update: Update) throws {
    logger.emit(.info, "Updating History with \(update)")
    
    let updateWorkItem = DispatchWorkItem {
      Task.detached {
        try self.db.write { db in
          try History.all().filter(id: update.key).updateAll(db, update.assignment)
        }
      }
    }
    
    DispatchQueue.global().async(execute: updateWorkItem)
  }
  
  
  func fetchItems(_ request: Query) throws -> [Entry] {
    try db.dumpRequest(request, format: Constants.grdbJsonDumpFormat)
    
    return try db.read { db in
      try request.fetchAll(db)
    }
  }
  
  
  func logError(_ error: ContentObserverError) {
    logger.emit(.error, ErrorMsg(error.description))
  }
  
  func logUpdate(_ message: String) {
    logger.emit(.info, message)
  }
}


enum ContentObserverError: Error {
  case missingRenameTask(IndexHistoryInfo)
  case failedRenameTask(RenameTask)
  case unknownColumn(IndexHistoryInfo)
  case unexpected(String, Error)
  
  var description: String {
    switch self {
    case .unexpected(let msg, let err):
      return "\(msg): \(err.localizedDescription)"
      
    case .missingRenameTask(let info):
      return "Missing rename task for \(info.index.url)"
      
    case .unknownColumn(let info):
      return "Update to unknown column \(info.transaction.columnName) for \(info.index.url)"
      
    case .failedRenameTask(let task):
      return task.failureMessage
    }
  }
}


extension DatabaseRegionObservation {
  
  var logger: Logger {
    EnvContainer.shared.logger("DatabaseRegionObservation")
  }
  
  func start(
      in writer: any DatabaseWriter,
      named name: String,
      onChange changeFn: @escaping @Sendable (Database) throws -> Void)
  -> AnyDatabaseCancellable {
    
    let onErrorFn: @Sendable (Error) -> Void = { error in
      self.logger.emit(.error, ErrorMsg("Error in database observer '\(name)'", error))
    }
    
    let onChangeFn: @Sendable (Database) -> Void = { db in
      do {
        try changeFn(db)
      } catch {
        self.logger.emit(.error, ErrorMsg("Error in database observer '\(name)'", error))
      }
    }
    
    return self.start(in: writer, onError: onErrorFn, onChange: onChangeFn)
  }
}
