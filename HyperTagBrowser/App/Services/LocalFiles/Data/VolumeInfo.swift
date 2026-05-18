// created on 11/21/24 by robinsr

import Foundation
import Regex


extension URL {
  
  var volumeInfo: VolumeInfo? {
    guard self.filepath.exists else { return nil }
    return VolumeInfo(url: self)
  }
  
  func getBookmarkData() throws -> Data {
    try self.bookmarkData(
      options: [],
      includingResourceValuesForKeys: [.volumeNameKey, .volumeURLKey, .volumeIdentifierKey, .volumeIsRootFileSystemKey],
      relativeTo: nil
    )
  }
  
  var isMounted: Bool {
    return (try? self.checkPromisedItemIsReachable()) == true
  }
  
  /**
   * The volume containing this url is browsable (eg is mounted)
   */
  var volumeIsBrowsable: Bool {
    self.volumeInfo?.isBrowsable ?? false
  }
  
  /**
   * The volume containing this url is writable (eg not read-only)
   */
  var volumeIsWritable: Bool {
    self.volumeInfo?.isWritable ?? false
  }
  
  /**
   * The (likely) volume name, derived from `.volumeNameKey` if reachable, else derived
   * from path if the URL points under /Volumes/<Name>/...
   */
  var volumeName: String {
    if isMounted {
      if let name = try? self.resourceValues(forKeys: [.volumeNameKey]).volumeName {
        return name
      }
    }
    
    let components = self.standardized.pathComponents
    guard components.count > 2, components[1] == "Volumes" else { return "Unknown Volume" }
    return components[2]
  }
}


struct VolumeInfo: Encodable {
  static let defaultVolumeName = "Macintosh HD"
  
  let url: URL
  
  var isVolume: Bool {
    url.boolResourceValue(forKey: .isVolumeKey)
  }
  
  var name: String {
    url.volumeName
  }
  
  var uuid: String {
    url.resourceValue(forKey: .volumeUUIDStringKey) ?? ""
  }
  
  var identifier: String {
    url.resourceValue(forKey: .volumeIdentifierKey) ?? ""
  }
  
  var subtype: String {
    url.resourceValue(forKey: .volumeSubtypeKey) ?? ""
  }
  
  var isReadable: Bool {
    url.boolResourceValue(forKey: .isReadableKey)
  }
  
  var isWritable: Bool {
    url.boolResourceValue(forKey: .isWritableKey)
  }
  
  var isRemovable: Bool {
    url.boolResourceValue(forKey: .volumeIsRemovableKey)
  }
  
  var isInternal: Bool {
    url.boolResourceValue(forKey: .volumeIsInternalKey)
  }
  
  var isEjectable: Bool {
    url.boolResourceValue(forKey: .volumeIsEjectableKey)
  }
  
  var isBrowsable: Bool {
    url.boolResourceValue(forKey: .volumeIsBrowsableKey)
  }
  
  var isReadOnly: Bool {
    url.boolResourceValue(forKey: .volumeIsReadOnlyKey)
  }
  
  var isEncrypted: Bool {
    url.boolResourceValue(forKey: .volumeIsEncryptedKey)
  }
  
  var isRoot: Bool {
    url.boolResourceValue(forKey: .volumeIsRootFileSystemKey)
  }
}
