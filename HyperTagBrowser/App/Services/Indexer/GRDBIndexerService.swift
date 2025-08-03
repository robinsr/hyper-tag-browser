// created on 10/14/24 by robinsr

import Factory
import Defaults
import Foundation
import GRDB
import GRDBQuery
import IssueReporting
import Regex
import Combine


struct GRDBIndexService: IndexerConnection, IndexerService {
  
  typealias Errors = IndexerServiceError
  
  public static let queryableOptions = [QueryableOptions.async, QueryableOptions.constantRegion]
  
  internal static var logger = EnvContainer.shared.logger("GRDBIndexService")
  internal let logger = EnvContainer.shared.logger("GRDBIndexService")
  internal var fs = Container.shared.fileService()
  internal var metadata = Container.shared.metadataService()
  
  let indexInfoQueryCache = IndexerContainer.shared.indexerQueryCache()
  
  let timer = Container.shared.timer()
  
  var dbName: String
  var cancellables: Set<AnyCancellable> = []
  var error: IndexerServiceError?
  var dbPool: DatabasePool? = nil
  var dbQueue: DatabaseQueue? = nil
  
  var dbReader: DatabaseReader {
    if let pool = dbPool { return pool }
    if let queue = dbQueue { return queue }
    
    fatalError("No database reader available")
  }
  
  var dbWriter: DatabaseWriter {
    if let pool = dbPool { return pool }
    if let queue = dbQueue { return queue }
    
    fatalError("No database writer available")
  }
  
  let sqlLogger = SQLQueryFormatter(namespace: "\(#file):\(Self.self)")
  private var thumbnailQueue = DispatchQueue(label: "thumbnailQueue")
  
  init(path dbURL: URL) throws {
    self.dbName = dbURL.filenameWithoutExtension
    
    if !fs.exists(at: dbURL) {
      logger.emit(.info, "Creating new database at \(dbURL.path)")
      
      do {
        try fs.touch(dbURL)
      } catch {
        self.error = IndexerServiceError.InitializationError(error)
        throw self.error!
      }
    }
    
    do {
      self.dbPool = try DatabasePool(path: dbURL.path, configuration: Self.configure())
    } catch {
      self.error = IndexerServiceError.InitializationError(error)
      throw self.error!
    }
  }
  
  init(named dbName: String) throws {
    do {
      self.dbName = dbName
      self.dbQueue = try DatabaseQueue(named: dbName, configuration: Self.configure())
    } catch {
      self.error = IndexerServiceError.InitializationError(error)
      throw self.error!
    }
  }
  
  func invalidate() {
    if let pool = dbPool {
      pool.invalidateReadOnlyConnections()
    }
  }
  
    // Set up the database connection
  func runMigrations() throws {
    let migrator = createMigrator()
    var upToDate = false
    var completedMigrations: [String] = []
    
    try dbReader.read { db in
      upToDate = try migrator.hasCompletedMigrations(db)
      completedMigrations = try migrator.completedMigrations(db)
    }
    
    completedMigrations.forEach {
      logger.emit(.info, "Migrated to: \($0)")
    }
    
    if upToDate {
      logger.emit(.success, "Database \(dbName) is up to date")
    } else if let latestDef = migrator.migrations.last {
      logger.emit(.warning, "Migrating database \(dbName) up to \(latestDef)")
      try migrator.migrate(dbWriter, upTo: latestDef)
    } else {
      logger.emit(.error, "No migrations found for database \(dbName)")
    }
    
    logger.emit(.info, "Vacuuming database")
    
    try dbWriter.vacuum()
    
    
    try dbWriter.write { db in
      for view in SchemaConfiguration.views {
        if try db.viewExists(view.databaseTableName) {
          try db.drop(view: view.databaseTableName)
        }
        
        try db.createView(from: view)
        
        try IndexHistory.createTriggers(db, recreate: true)
      }
    }
  }
  
    // Set up the database connection
  func runAsyncMigrations() async throws -> Future<String, Error> {
    
    let migrator = createMigrator()
    
    
    let (upToDate, completedMigrations) = try await dbReader.read { db in
      (try migrator.hasCompletedMigrations(db), try migrator.completedMigrations(db))
    }
    
    let latest = migrator.migrations.last
    
    return Future<String, Error> { promise in

      completedMigrations.forEach {
        logger.emit(.info, "Migrated to: \($0)")
      }
        
      if upToDate {
        logger.emit(.success, "Database \(dbName) is up to date")
        
        promise(.success(latest ?? "v0"))
      }
      
      else if let latestDef = migrator.migrations.last {
        logger.emit(.warning, "Migrating database \(dbName) up to \(latestDef)")
        
        migrator.asyncMigrate(dbWriter) { result in
          logger.emit(.info, "Migration progress: \(result)")
          
          if case .failure(let error) = result {
            promise(.failure(error))
          } else {
            promise(.success(latestDef))
          }
        }
      }
      
      else {
        logger.emit(.error, "No migrations found for database \(dbName)")
        
        promise(.success("v0"))
      }
    }
  }
  
  static func configure() -> Configuration {
    var config = Configuration()
    
    config.publicStatementArguments = Defaults[.devFlags].contains(.indexer_enableSqlTrace)
    
    config.readonly = false
    
    config.prepareDatabase { db in
      
      for fn in DatabaseFunctions.allCases {
        db.add(function: fn.function)
      }
      
      // Database Reader config below
      guard db.configuration.readonly else { return }
  
      if Defaults[.devFlags].contains(.indexer_enableSqlTrace) {
        let formatter = SQLTraceFormatter(enabledTables: SchemaConfiguration.tableNames)
        
        db.trace(options: .statement) { evt in
          if !formatter.skipStatement(evt) {
            formatter.formatAndPrint(evt)
          }
        }
      }
        
      if Defaults[.devFlags].contains(.indexer_enableSqlProfiling) {
        db.trace(options: .profile) { evt in
          logger.emit(.stats, "SQL Profile: \(evt.description)")
        }
      }
    }
    
    return config
  }
  
  func createMigrator() -> DatabaseMigrator {
      // TODO: Figureout database migrations
    var migrator = DatabaseMigrator()
    
    let queue = DispatchQueue(label: "test")
    
    let cancellable = migrator.migratePublisher(dbWriter, receiveOn: queue).sink(
      receiveCompletion: { completion in
        dispatchPrecondition(condition: .onQueue(queue))
          
      },
      receiveValue: { _ in
        dispatchPrecondition(condition: .onQueue(queue))
          
      })
    
    cancellable.cancel()

    
    let versions = MigrationVersions.Version.allVersions
    
    versions
      .compactMap { MigrationVersions.get(version: $0) }
      .filter { $0.state.oneOf(.ready, .testing) }
      .forEach { config in
        let dbVersion = config.version.rawValue
        
        migrator.registerMigration(dbVersion) { (db: Database) in
          
          logger.warning("""
          Running Migration: '\(dbVersion)'
            \(config.description)
          """)
          
          guard let status = try? config.checkFn(db) else {
            throw IndexerServiceError.OperationFailed("Migration '\(dbVersion)' failed to check status")
          }
          
          if status != .unmigrated {
            logger.emit(.info, "Skipping '\(dbVersion)' invalid status (\(status))")
            return
          }
          
          if status == .unmigrated && config.state == .ready {
            try config.migrate(db)
          }
          
          if status == .unmigrated && config.state == .testing {
            let dbFolder = URL(fileURLWithPath: self.dbWriter.path).deletingLastPathComponent()
            let snapshotPath = config.snapshotPath(dir: dbFolder).path()
            
            try fs.touch(.init(fileURLWithPath: snapshotPath))
            
            logger.emit(.info, "Testing migration '\(dbVersion)'; saving snapshot to \(snapshotPath)")

            try config.migrate(db)
            
            logger.emit(.info, "Testing migration '\(dbVersion)' complete, saving snapshot to \(snapshotPath)")

            // try db.backup(to: DatabaseQueue(path: snapshotPath))
            
            
            Task.detached(priority: .background) {
              let destDbQueue = try DatabaseQueue(path: snapshotPath, configuration: Configuration())
              
              try destDbQueue.barrierWriteWithoutTransaction { destDb in
                try db.backup(to: destDb)
              }
            }
            
            logger.emit(.info, "Testing migration '\(dbVersion)' snapshot saved, reverting")

            try db.rollback()
          }
        }
      }

    return migrator
  }
  
  
  internal func opFailed(_ message: String, url: URL, err: Error? = nil) -> IndexerServiceError {
    let attributes: [String: Any] = [
      NSURLErrorKey: url,
    ]
    
    let error = IndexerServiceError.OperationFailed(message, err: err, attributes: attributes)
    
    logger.emit(.error, .raised(error.legibleDescription, error.originalError ?? error))
    
    return error
  }
  
  internal func opFailed(_ message: String, err: Error? = nil) -> IndexerServiceError {
    opFailed(message, url: .null, err: err)
  }
  
  internal func dataIntegrityError(_ message: String, ids: [String]) -> IndexerServiceError {
    let attributes: [String: Any] = [
      "Related IDs": ids,
    ]
    
    let error = IndexerServiceError.DataIntegrityError(message, attributes: attributes)
    
    logger.emit(.error, .raised(error.legibleDescription, error.originalError ?? error))
    
    return error
  }
}
