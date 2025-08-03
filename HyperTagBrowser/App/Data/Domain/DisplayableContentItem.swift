// created on 10/16/24 by robinsr

import Foundation
import SwiftUI
import System
import UniformTypeIdentifiers


protocol IdentifiableContentItem: Identifiable {
  var id: ContentId { get }
  var pointer: ContentPointer { get }
}

typealias AnyIdentifiableContentItem = any IdentifiableContentItem


protocol FileSystemContentItem {
  var url: URL { get }
  var filepath: FilePath { get }
  var location: FilePath { get }
  var name: String { get }
  var exists: Bool { get }
  func conforms(to: UTType) -> Bool
}

typealias AnyFileSystemContentItem = any FileSystemContentItem




/**
 Conforming to `DisplayableContentItem` allows for the underlying
 content type to be displayed on any View that accepts a
 `DisplayableContentItem` as a parameter. This allows view components
 to be useable more widely and not bound to how the content was
 provided (Database record, local filesystem, Spotlight "MetadataItem", etc)
 */
protocol DisplayableContentItem: IdentifiableContentItem, FileSystemContentItem, Hashable, Identifiable, Equatable, Encodable where ID == ContentId {
//  var id: ContentId { get }
//  var pointer: ContentPointer { get }
//  var url: URL { get }
//  var filepath: FilePath { get }
//  var location: FilePath { get }
//  var name: String { get }
//  var exists: Bool { get }
  
  var index: IndexRecord { get }
  var tags: [FilteringTag] { get }
  var link: Route { get }
}

typealias AnyDisplayableContentItem = any DisplayableContentItem


  // Extensions enabled by the ContentIdentifier protocol (ContentId, ContentPointer, etc)
extension Sequence where Element : IdentifiableContentItem {
  
  var ids: [ContentId] {
    self.map(\.id)
  }
  
  var pointers: [ContentPointer] {
    self.map(\.pointer)
  }
  
  func contains(_ id: ContentId) -> Bool {
    self.contains { $0.id == id }
  }
  
  func item(for id: ContentId) -> Element? {
    self.first { $0.id == id }
  }
}


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


  // Extensions enabled by the DisplayableContentItem protocol (IndexRecord, tags, link, etc)
extension Sequence where Element : DisplayableContentItem {
  
  var records: [IndexRecord] {
    self.map(\.index)
  }
  
  func visibility(eq val: ContentItemVisibility) -> [Element] {
    self.filter { $0.index.visibility == val }
  }
}
