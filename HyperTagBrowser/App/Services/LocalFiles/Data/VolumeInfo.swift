// created on 11/21/24 by robinsr

import Foundation
import Regex


extension URL {
  
  var volumeInfo: VolumeInfo? {
    guard FileManager.default.fileExists(at: self) else { return nil }
    
    return VolumeInfo(url: self)
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
   * The name of the volume containing this url, or "Macintosh HD" if not available
   */
  var volumeName: String {
    self.volumeInfo?.name ?? VolumeInfo.defaultName
  }
}


struct VolumeInfo: Encodable {
  let url: URL
  let isVolume: Bool
  let name: String
  let uuid: String
  let identifier: String
  let subtype: String
  let isRoot: Bool
  let isReadable: Bool
  let isWritable: Bool
  let isRemovable: Bool
  let isInternal: Bool
  let isEjectable: Bool
  let isBrowsable: Bool
  let isReadOnly: Bool
  let isEncrypted: Bool
  
  init(url: URL) {
    self.url = url
    
    isVolume = url.boolResourceValue(forKey: .isVolumeKey)
    name = url.resourceValue(forKey: .volumeNameKey) ?? ""
    uuid = url.resourceValue(forKey: .volumeUUIDStringKey) ?? ""
    identifier = url.resourceValue(forKey: .volumeIdentifierKey) ?? ""
    subtype = url.resourceValue(forKey: .volumeSubtypeKey) ?? ""
    isRoot = url.boolResourceValue(forKey: .volumeIsRootFileSystemKey)
    isReadable = url.boolResourceValue(forKey: .isReadableKey)
    isWritable = url.boolResourceValue(forKey: .isWritableKey)
    isRemovable = url.boolResourceValue(forKey: .volumeIsRemovableKey)
    isInternal = url.boolResourceValue(forKey: .volumeIsInternalKey)
    isEjectable = url.boolResourceValue(forKey: .volumeIsEjectableKey)
    isBrowsable = url.boolResourceValue(forKey: .volumeIsBrowsableKey)
    isReadOnly = url.boolResourceValue(forKey: .volumeIsReadOnlyKey)
    isEncrypted = url.boolResourceValue(forKey: .volumeIsEncryptedKey)
  }
  
  var displayName: String {
    if isRoot {
      return Self.defaultName
    }
    
    if name.notEmpty {
      return name
    }
    
    let volumeNameRegex = Regex(#"^\/Volumes\/([^\/]+)\/.*$"#)
    
    return volumeNameRegex.firstMatch(in: url.filepath.string)?.captures[0] ?? "Unknown"
  }
  
  static let defaultName = "Macintosh HD"
}
