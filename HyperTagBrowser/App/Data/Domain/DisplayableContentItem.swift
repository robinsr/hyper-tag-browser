// created on 10/16/24 by robinsr

import Foundation
import SwiftUI
import System
import UniformTypeIdentifiers


protocol IdentifiableContentItem: Identifiable {
  var id: ContentId { get }
  var pointer: ContentPointer { get }
}


protocol FileSystemContentItem {
  var url: URL { get }
  var filepath: FilePath { get }
  var location: FilePath { get }
  var name: String { get }
  var exists: Bool { get }
  func conforms(to: UTType) -> Bool
}

typealias AnyFileSystemContentItem = any FileSystemContentItem



  // Extensions enabled by the FileSystemContentItem protocol (URL, FilePath, UTType, etc)
extension Sequence where Element : FileSystemContentItem {
  
  func orderedFoldersFirst() -> [Element] {
    self.sorted {
      let aIsDir = $0.conforms(to: .folder)
      let bIsDir = $1.conforms(to: .folder)
      
      return aIsDir && !bIsDir // Folders come first
    }
  }

  func whereFileExists(_ shouldExist: Bool = true) -> [Element] {
    self.filter { $0.exists == shouldExist }
  }
  
  func conforms(to: UTType) -> [Element] {
    self.filter { $0.conforms(to: to) }
  }
  
  func diverges(from: UTType) -> [Element] {
    // Returns items that do not conform to the given UTType
    self.filter { !$0.conforms(to: from) }
  }
}

