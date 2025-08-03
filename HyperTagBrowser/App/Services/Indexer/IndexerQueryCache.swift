// created on 8/2/25 by robinsr

import Cache
import Factory
import Foundation
import System


struct IndexerQueryCache {
  
  typealias CacheKey = String // BrowseQueryParameters.hashValue
  typealias CacheValue = IndexInfoRecord
  
  private let logger = EnvContainer.shared.logger("IndexerQueryCache")
  

  private let diskCacheConfiguration: DiskConfig = {
    let dir = EnvContainer.shared.stagedPath().appending("querystore").filepath
    
    return DiskConfig(
      name: dir.string,
      expiry: .minutes(90),
      protectionType: .complete
    )
  }()

  private let memoryCacheConfiguration: MemoryConfig = {
    MemoryConfig(
      expiry: .minutes(30),
      countLimit: 10,
      totalCostLimit: 10
    )
  }()

  private let store: Storage<CacheKey, [CacheValue]>


  init() {
    store = try! Storage<CacheKey, [CacheValue]>(
      diskConfig: diskCacheConfiguration,
      memoryConfig: memoryCacheConfiguration,
      fileManager: FileManager.default,
      transformer: TransformerFactory.forCodable(ofType: [CacheValue].self)
    )
  }
  
  func get(_ key: CacheKey) -> [CacheValue]? {
    do {
      return try store.object(forKey: key)
    } catch {
      logger.emit(.error, "Failed to retrieve cache for key \(key): \(error)")
      return nil
    }
  }
  
  func set(_ key: CacheKey, value: [CacheValue]) {
    do {
      try store.setObject(value, forKey: key)
    } catch {
      logger.emit(.error, "Failed to set cache for key \(key): \(error)")
    }
  }
  
  func remove(_ key: CacheKey) {
    do {
      try store.removeObject(forKey: key)
    } catch {
      logger.emit(.error, "Failed to remove cache for key \(key): \(error)")
    }
  }
  
  func has(_ key: CacheKey) -> Bool {
    guard let exists = try? store.existsObject(forKey: key) else { return false }

    return exists
  }
}
