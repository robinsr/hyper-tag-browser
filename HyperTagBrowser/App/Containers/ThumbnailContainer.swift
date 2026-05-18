// created on 11/9/25 by robinsr

import Cache
import Factory
import Foundation
import System


public final class ThumbnailContainer: SharedContainer {
  public static let shared = ThumbnailContainer()
  public let manager = ContainerManager()
  
  private let logger = EnvContainer.shared.logger("ThumbnailContainer")
  

  var store: Factory<ThumbnailStore> {
    self { @MainActor in
      ThumbnailStore()
    }
    .scope(.cached)
  }
  
  var cache: Factory<Storage<ContentId, Data>> {
    self {
      try! Storage<ContentId, Data>(
        diskConfig: self.diskConfig(),
        memoryConfig: self.memConfig(),
        fileManager: FileManager.default,
        transformer: TransformerFactory.forData()
      )
    }
    .scope(.singleton)
  }
  
  var cacheName: Factory<String> {
    self {
      let prefix = EnvContainer.shared.domainStage()
      
      return "\(prefix).thumbstore"
    }
    .scope(.singleton)
  }
  
  var diskConfig: Factory<DiskConfig> {
    self {
      let name = self.cacheName()
      
      return DiskConfig(name: name, expiry: .days(15))
    }
    .scope(.singleton)
  }
  
  var memConfig: Factory<MemoryConfig> {
    self {
      MemoryConfig(expiry: .minutes(30), countLimit: 10, totalCostLimit: 10)
    }
    .scope(.singleton)
  }
}



extension Expiry {
  static func minutes(_ minutes: Int) -> Expiry {
    return .seconds(TimeInterval(minutes * 60))
  }
  
  static func hours(_ hours: Int) -> Expiry {
    return .seconds(TimeInterval(hours * 60 * 60))
  }
  
  static func days(_ days: Int) -> Expiry {
    return .seconds(TimeInterval(days * 24 * 60 * 60))
  }
}
