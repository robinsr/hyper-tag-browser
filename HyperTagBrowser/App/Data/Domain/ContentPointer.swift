// created on 10/16/24 by robinsr

import CoreTransferable
import Factory
import Foundation
import System
import UniformTypeIdentifiers



struct ContentPointer: Identifiable, Codable {
  typealias ID = String
  
  let contentId: ContentId
  let contentPath: FilePath
  
  var contentURL: URL {
    contentPath.fileURL
  }
  
  var contentLocation: URL {
    contentURL.directoryURL
  }
  
  var contentName: String {
    contentURL.lastPathComponent
  }
  
  var contentType: UTType {
    contentURL.contentType
  }
  
  var id: String {
    "\(contentId.value)-\(contentPath.string)"
  }
  
  var link: Route {
    if contentType.conforms(to: .folder) {
      return .folder(contentPath)
    } else {
      return .content(self)
    }
  }

  init(id: ContentId, filepath: FilePath) {
    self.contentId = id
    self.contentPath = filepath
  }
  
  @available(*, deprecated, message: "Use init(id:filePath:) instead")
  init(id: ContentId, fileURL: URL) {
    self.init(id: id, filepath: fileURL.filepath)
  }
  
  init(filePath path: FilePath) {
    self.init(id: .newID(filepath: path), filepath: path)
  }
  
  @available(*, deprecated, message: "Use init(filePath:) instead")
  init(fileURL url: URL) {
    self.init(id: .newID(filepath: url.filepath), filepath: url.filepath)
  }
  
  static func == (lhs: ContentPointer, rhs: ContentPointer) -> Bool {
    lhs.id == rhs.id
  }
}

extension ContentPointer: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(contentId.value)
    hasher.combine(contentPath.string)
  }
}


extension ContentPointer: CustomStringConvertible {
  var description: String {
    """
    ContentPointer(
      contentId=\(contentId.value)
      contentPath=\(contentPath.string)
    )
    """
  }
}


struct ContentPointers: Codable, Transferable {
  let values: [ContentPointer]
  
  init(_ values: [ContentPointer]) {
    self.values = values
  }

  init(_ value: ContentPointer) {
    self.init([value])
  }
  
  var isEmpty: Bool { values.isEmpty }
  var notEmpty: Bool { values.isEmpty == false  }

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(contentType: .contentPointer) { pointers in
      try JSONEncoder().encode(pointers)
    } importing: { data in
      let pointers = try JSONDecoder().decode(ContentPointers.self, from: data)
      return ContentPointers(pointers.values)
    }
  }
  
  static var empty: ContentPointers {
    ContentPointers([])
  }
}


extension ContentPointer: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .contentPointer)
  }
}


extension Collection where Element == ContentPointer {
  var string: String {
    self.map(\.contentId.value).joined(separator: ", ")
  }
  
  var ids: [ContentId] {
    self.map(\.contentId)
  }
  
  subscript(_ id: ContentId) -> ContentPointer? {
    self.first { $0.contentId == id }
  }
  
  subscript(path: FilePath) -> ContentPointer? {
    self.first { $0.contentPath == path }
  }
}
