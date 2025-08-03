// created on 10/14/24 by robinsr

import Foundation


extension LocalFileService {
  
  enum URLResourceKeySet {
    case basic
    case volume
    
    var resourceKeys: [URLResourceKey] {
      switch self {
      case .volume: Self.volumeAttributes
      default: Self.basicAttributes
      }
    }
    
    static let basicAttributes: [URLResourceKey] = [
      .attributeModificationDateKey,
      .contentAccessDateKey,
      .contentModificationDateKey,
      .contentModificationDateKey,
      .contentTypeKey,
      .creationDateKey,
      .fileAllocatedSizeKey,
      .fileSizeKey,
      .isDirectoryKey,
      .isExecutableKey,
      .isHiddenKey,
      .isReadableKey,
      .isWritableKey,
      .nameKey,
      .totalFileAllocatedSizeKey,
      .totalFileSizeKey,
    ]
    
    static let volumeAttributes: [URLResourceKey] = [
      .volumeNameKey,
      .volumeTotalCapacityKey,
      .volumeAvailableCapacityKey,
      .volumeIsRemovableKey,
      .volumeIsEjectableKey,
      .volumeIsInternalKey,
      .volumeIsRootFileSystemKey,
    ]
  }
}
