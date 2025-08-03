// created on 3/6/25 by robinsr

import Cache
import Foundation


  /// Options for the `ListMode` enumeration.
enum FileCachingOption: String, Codable, CaseIterable {
  case cached, uncached
  
  var expires: TimeInterval {
    switch self {
    case .cached: return 180
    case .uncached: return 10
    }
  }
  
  var discConfig: DiskConfig {
    DiskConfig(name: "fs-cache", expiry: .seconds(expires))
  }
  
  var memConfig: MemoryConfig {
    MemoryConfig(expiry: .seconds(expires), countLimit: 3000, totalCostLimit: 10)
  }
}
