// created on 4/8/25 by robinsr

import Cache
import Factory
import Foundation
import GRDB
import System


public final class IndexerContainer: SharedContainer {
  public static let shared = IndexerContainer()
  
  public let manager = ContainerManager()
  private let root = EnvContainer.shared
  private let prefs = PreferencesContainer.shared
  private let logger = EnvContainer.shared.logger("IndexerContainer")
  
  
  var dbURL: Factory<URL> {
    self {
      self.prefs.userProfile().dbFile
    }
    .context(.preview) {
      TestData.dbFile
    }
    .context(.debug) {
      TestData.dbFile
    }
    .context(.test) {
      TestData.dbFile
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
      do {
        let databaseURL = self.dbURL()
        
        self.logger.emit(.debug, "Opening database at \(databaseURL.filepath.string)")
        
        return try GRDBIndexService(path: databaseURL)
      } catch {
        self.logger.emit(.critical, "Failed to open the intended database: \(error)")
        
        return self.inMemoryIndexService()
      }
    }
    .scope(.cached)
  }

  
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
  
  var databaseObserver: Factory<ContentItemRenamedObserver> {
    self {
      ContentItemRenamedObserver()
    }
    .scope(.cached)
  }
  
  var indexerQueryCache: Factory<IndexerQueryCache> {
    self {
      IndexerQueryCache()
    }
    .scope(.cached)
  }
}
