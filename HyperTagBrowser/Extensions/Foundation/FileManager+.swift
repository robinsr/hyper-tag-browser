// created on 12/23/25 by robinsr

import Foundation

extension FileManager {
  func directoryExists(at url: URL) -> Bool {
    directoryExists(atPath: url.path)
  }
  
  func directoryExists(atPath path: String) -> Bool {
    var isDir: ObjCBool = true
    return fileExists(atPath: path, isDirectory: &isDir)
  }
  
  func fileExists(at url: URL) -> Bool {
    fileExists(atPath: url.path)
  }
}
