// created on 10/14/24 by robinsr

import Foundation
import Factory
import Cache


final class LocalFileCache {

  private var logger = EnvContainer.shared.logger("LocalFileServiceCache")
  
  typealias Key = CacheKey
  typealias Entry = CacheEntry
  typealias Store = Storage<Key, Entry>
  
  
  var keys: Set<Key> = []
  var tokens: [ObservationToken] = []
  
  lazy var stores: [FileCachingOption: Store] = {
    var stores: [FileCachingOption: Store] = [:]
    
    stores[.cached] = try! Storage(
      diskConfig: FileCachingOption.cached.discConfig,
      memoryConfig: FileCachingOption.cached.memConfig,
      fileManager: FileManager.default,
      transformer: TransformerFactory.forCodable(ofType: LocalFileCache.CacheEntry.self))
    
    stores[.uncached] = try! Storage(
      diskConfig: FileCachingOption.uncached.discConfig,
      memoryConfig: FileCachingOption.uncached.memConfig,
      fileManager: FileManager.default,
      transformer: TransformerFactory.forCodable(ofType: LocalFileCache.CacheEntry.self))
    
    return stores
  }()
  
  private var allStores: [LocalFileCache.Store] {
    stores.values.map { $0 }
  }
  
  private func getStore(forConfig config: FileCachingOption) -> LocalFileCache.Store {
    stores[config]!
  }
  
  
  init() {
    for type in FileCachingOption.allCases {
      tokens.append(stores[type]!.addStorageObserver(self) { observer, storage, change in
        switch change {
        case .add(let key):
          self.keys.toggleExistence(key, shouldExist: true)
          
          self.logger.emit(.debug, "Observed cache add with key: \(key)")
        case .remove(let key):
          self.keys.toggleExistence(key, shouldExist: false)
          self.logger.emit(.debug, "Observed cache remove with key: \(key)")
        case .removeAll:
          self.keys.removeAll()
          self.logger.emit(.debug, "Observed cache remove all")
        case .removeExpired:
          print("Removed expired")
        case .removeInMemory(key: let key):
          print("Removed in memory \(key)")
        }
      })
    }
  }

  
  deinit {
    for token in tokens {
      token.cancel()
    }
  }
  
  func add(forParams params: CacheKey, items: ContentPointerURLMapping) {
    let store = stores[params.cache]!
    
    do {
      let data = CacheEntry(parameters: params, items: items)
      
      try store.setObject(data, forKey: params)
      
      if let diskSizeBytes = store.totalDiskStorageSize {
        logger.emit(.debug, "Added cache entry; total size: \(diskSizeBytes) bytes")
      }
    } catch {
      logger.emit(.error, "Could not add cache entry for \(params): \(error)")
    }
  }
  
  func get(forParams params: CacheKey) -> CacheEntry? {
    let store = stores[params.cache]!
    
    do {
      let exists = try store.existsObject(forKey: params)
      
      guard exists else {
        print("Cache miss for \(params)")
        return nil
      }
      
      return try store.object(forKey: params)
    } catch {
      logger.emit(.error, "Could not get cache entry for \(params): \(error)")
      return nil
    }
  }
  
  func reset() throws {
    for store in allStores {
      try store.removeAll()
    }
  }
  
  func evictBy(matchingURL url: URL) {
    let evictKeys = keys.filter { $0.dir == url }
    
    for store in allStores {
      for key in evictKeys {
        try? store.removeObject(forKey: key)
      }
    }
  }
  
  
  struct CacheEntry: Identifiable, Codable {
    let parameters: CacheKey
    let items: ContentPointerURLMapping
    
    var id: CacheKey.ID {
      parameters.id
    }
  }

  
  struct CacheKey: Identifiable, Equatable, Hashable, Codable {
    let dir: URL
    let id: String
    let cache: FileCachingOption
    
    init(dir: URL, mode: ListMode, types: String) {
      self.dir = dir
      self.id = "\(dir.absoluteString);\(mode.description);\(types);"
      self.cache = mode.cacheConfig
    }
  }
}
