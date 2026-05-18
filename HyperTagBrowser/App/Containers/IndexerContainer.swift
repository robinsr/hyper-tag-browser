// created on 4/8/25 by robinsr

import Cache
import Factory
import Foundation
import GRDB
import GRDBQuery
import System
//import DequeModule


public final class IndexerContainer: SharedContainer {
  public static let shared = IndexerContainer()
  
  public let manager = ContainerManager()
  private let root = EnvContainer.shared
  private let prefs = PreferencesContainer.shared
  
  private let logger = CustomLogger("IndexerContainer", level: .debug)
  
  
  var databasePath: Factory<FilePath> {
    self {
      self.prefs.userProfile().dbFile.filepath
    }
    .onPreview {
      UserLocation.homePath.appending("workspace/xcode/TaggedFileBrowser/previewdb.sqlite")
    }
    .onTest {
      UserLocation.homePath.appending("workspace/xcode/TaggedFileBrowser/previewdb.sqlite")
    }
    .scope(.cached)
  }
  
  var newDbURL: ParameterFactory<String, URL> {
    self { name in
      let stageId = self.root.stageId()
      let dbFilename = ["userdb", stageId, name, "sqlite"].dotPath
      
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
      DispatchQueue(label: "\(Constants.appdomain).indexTaskQueue")
    }
    .scope(.singleton)
  }
  
  
  var indexerQueryCache: Factory<IndexerQueryCache> {
    self {
      IndexerQueryCache()
    }
    .scope(.cached)
  }
}
