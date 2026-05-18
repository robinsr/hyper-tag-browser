// created on 10/14/24 by robinsr

import Combine
import Defaults
import Factory
import Foundation
import GRDB
import GRDBQuery
import Regex
import System


struct GRDBDatabaseOptions: Sendable {
  public static let queryableOptions = [QueryableOptions.async, QueryableOptions.constantRegion]
}


actor GRDBIndexService: IndexerConnection, IndexerService {
  
  let logger = CustomLogger("GRDBIndexService", level: .warning)
  let dbName: String
  let dbReader: DatabaseReader
  let dbWriter: DatabaseWriter
  
  private let dbPool: DatabasePool?
  private let dbQueue: DatabaseQueue?
  
  /**
   * Initializes GRDBIndexerService from a `FilePath` to a `.sqlite` file, creating
   * a DatabasePool-based database connection
   */
  init(path databasePath: FilePath) throws {
    self.dbName = databasePath.baseName
    
    if !databasePath.exists {
      logger.emit(.info, "Creating new database at \(databasePath.string)")
      
      do {
        try LocalFileService.init(monitoring: false).touch(databasePath.fileURL)
      } catch {
        throw IndexerServiceError.InitializationError(error)
      }
    }
    
    do {
      let database = try DatabasePool(path: databasePath.string, configuration: Self.configure())
      self.dbReader = database
      self.dbWriter = database
      self.dbPool = database
      self.dbQueue = nil
    } catch {
      throw IndexerServiceError.InitializationError(error)
    }
  }
  
  /**
   * Initializes GRDBIndexerService from a database name, creating a DatabaseQueue-based database connection
   */
  init(named dbName: String) throws {
    self.dbName = dbName
    
    do {
      let database = try DatabaseQueue(named: dbName, configuration: Self.configure())
      self.dbReader = database
      self.dbWriter = database
      self.dbQueue = database
      self.dbPool = nil
    } catch {
      throw IndexerServiceError.InitializationError(error)
    }
  }
  
  init(database: DatabaseQueue) {
    self.dbName = FilePath(database.path).baseName
    self.dbReader = database
    self.dbWriter = database
    self.dbQueue = database
    self.dbPool = nil
  }
  
  func invalidate() {
    if let pool = dbPool {
      pool.invalidateReadOnlyConnections()
    }
  }
  
    // Set up the database connection
  nonisolated func runMigrations() throws {
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

  
  static func configure() -> Configuration {
    var config = Configuration()
    config.publicStatementArguments = Defaults[.devFlags].contains(.indexer_enableSqlTrace)
    config.readonly = false
    config.maximumReaderCount = 4
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
    }
    
    return config
  }
  
  nonisolated func createMigrator() -> DatabaseMigrator {
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
          
          let logger = CustomLogger("GRDBIndexerService/Migration")
          
          logger.emit(.warning, "Running Migration: '\(dbVersion)' - \(config.description)")
          
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
        }
      }

    return migrator
  }
  
  
  internal func opFailed(_ message: String, url: URL, err: Error? = nil) -> IndexerServiceError {
    let error = IndexerServiceError.OperationFailed(message, err: err)
    logger.emit(.error, .raised(error.legibleDescription, error.originalError ?? error))
    return error
  }
  
  internal func opFailed(_ message: String, err: Error? = nil) -> IndexerServiceError {
    opFailed(message, url: .null, err: err)
  }
  
  internal func dataIntegrityError(_ message: String, ids: [String]) -> IndexerServiceError {
    let error = IndexerServiceError.DataIntegrityError(message)
    logger.emit(.error, .raised(error.legibleDescription, error.originalError ?? error))
    return error
  }
}
