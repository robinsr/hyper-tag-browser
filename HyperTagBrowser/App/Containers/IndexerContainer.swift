// created on 4/8/25 by robinsr

import Cache
import Factory
import Foundation
import GRDB
import GRDBQuery
import System


public final class IndexerContainer: SharedContainer {
  public static let shared = IndexerContainer()
  public let manager = ContainerManager()
  
  private let logger = CustomLogger("IndexerContainer", level: .debug)
  
  
  var databasePath: Factory<FilePath> {
    self {
      PreferencesContainer.shared.userProfile().dbFile.filepath
    }
    .onPreview { @MainActor in
      TestData.previewDb
    }
    .onPreview { @MainActor in
      TestData.previewDb
    }
    .scope(.cached)
  }
  
  var newDbURL: ParameterFactory<String, URL> {
    self { name in
      let stage = EnvContainer.shared.stage()
      let dbFilename = ["userdb", stage.id, name, "sqlite"].dotPath
      
      return AppLocation.appSupport.appending(dbFilename).fileURL
    }
  }

  
  //
  // MARK: - GRDB Section
  //
  
  var dbReader: Factory<GRDB.DatabaseReader> {
    self {
      self.indexService().dbReader
    }
    .scope(.cached)
  }
  
  var dbWriter: Factory<GRDB.DatabaseWriter> {
    self {
      self.indexService().dbWriter
    }
    .scope(.cached)
  }
  
  var dbContext: Factory<GRDBQuery.DatabaseContext> {
    self {
      .readOnly { self.dbReader() }
    }
    .scope(.cached)
    
  }

  var dbPath: Factory<String> {
    self {
      self.dbReader().path
    }
    .scope(.cached)
  }
  
  
  //
  // MARK: - IndexerService Section
  //
  
  var inMemoryIndexService: Factory<GRDBIndexService> {
    self {
      let dbName = "no-database-found-db"
      
      do {
        return try GRDBIndexService(named:dbName)
      } catch {
        fatalError("Failed to open in-memory index database (\(dbName)): \(error)")
      }
    }
    .scope(.cached)
  }
  
  var indexService: Factory<GRDBIndexService> {
    self {
      let dbPath = self.databasePath()
      
      self.logger.emit(.debug, "Opening database at \(dbPath.string)")
      
      do {
        return try GRDBIndexService(path: dbPath)
      } catch {
        fatalError("Failed to open in-memory index database (\(dbPath.string)): \(error)")
      }
    }
    .scope(.cached)
  }
  
  //
  // MARK: - Support
  //
  
  var indexTaskQueue: Factory<DispatchQueue> {
    self {
      let domain = EnvContainer.shared.domain()
      
      return DispatchQueue(label: "\(domain).indexTaskQueue")
    }
    .scope(.singleton)
  }
}
