// created on 10/10/24 by robinsr

import CryptoKit
import Factory
import Foundation
import GRDB
import OSLog
import Regex
import System


/**
 * A unique identifier used to identify content in the system.
 *
 * There are two types of IDs:
 * - `filename` - based on the file name and date created
 * - `content` - based on the file content
 *
 */
struct ContentId: Codable, Hashable, Equatable, Sendable {
  private static let logger = EnvContainer.shared.logger("ContentId")
  
  private static let IDLength = 32
  private static let IDPattern = #"^(filename|content|random):[\w\d]{\#(IDLength)}$"#
  private static let IDRegex = try! Regex(string: IDPattern)
  
  /**
   * A static ContentId that represents various "empty" scenarios
   */
  static let placeholder = ContentId(existing: Constants.noContentId)

  let value: String
  
  var id: String {
    self.value
  }
  
  var hashId: String {
    self.value.hashId
  }
  
  var uniqueId: String {
    guard let idRange = self.value.range(of: ":") else {
      return self.value
    }
    
    let idSuffix = self.value[idRange.upperBound...]
    
    return String(idSuffix)
  }
  
  var shortId: String {
    String(self.uniqueId.prefix(8))
  }
  
  var data: Data {
    value.data(using: .utf8)!
  }
  
  var source: ContentIdType {
    ContentIdType(rawValue: value)
  }
  
  var isEmpty: Bool {
    self == Self.placeholder
  }

  init?(data: Data) {
    self.value = String(data: data, encoding: .utf8)!
  }
  
  init?(_ data: Data) {
    self.init(data: data)
  }
  
  fileprivate init(string val: String) {
    self.value = val
  }
  
  init(existing id: String) {
    self.value = id
  }
  
  init(existing data: Data) {
    self.value = String(data: data, encoding: .utf8)!
  }
  
  static subscript(_ stringId: String) -> ContentId {
    ContentId(existing: stringId)
  }
  
  /**
   * Creates a new ContentId not associated to a file URL using a random string identifier
   */
  static func newID() -> ContentId {
    let source: ContentIdType = .random
    let ident: String = .randomIdentifier(Self.IDLength)
    
    return ContentId(string: "\(source.idPrefix):\(ident)")
  }
  
  /**
   * Manually specify the ID source for a new ContentId for the file at the given URL
   *
   * - If the source is `.filename` or `.folder`, the ID is based on the file or folder name.
   * - If the source is `.content`, a hash of the file content is used.
   * - If the source is `.random`, a random string identifier is used.
   *
   * ## TODO: Support contents-based ID that accounts for duplicate files with different names !!!
   *
   * Currently, duplicating a file with a fileContents-based contentID will result in two content entries
   * files with identical contentIds, confusing the content indexer.
   *
   * For now, we will use the filename-based ID for all files.
   */
  static func newID(using source: ContentIdType = .attributes, filepath: FilePath) -> ContentId {
    var id: String
    
    switch source.resolvedType {
    case .attributes:
      id = md5HashString(idString(for: filepath))
    case .content:
      id = fileContentsBasedId(filepath: filepath)
    case .random:
      id = .randomIdentifier(Self.IDLength)
    default:
      logger.emit(.warning, "Unhandled contentId generation source: \(source.rawValue). Falling back to random")
      
      id = .randomIdentifier(Self.IDLength)
    }
    
    return ContentId(string: "\(source.idPrefix):\(id)")
  }

  /**
   * Generates a content-based ID for the file at the given URL.
   */
  private static func fileContentsBasedId(filepath: FilePath) -> String {
    let failure = ModeledError
      .failed(to: "create ContentID from file contents file: '\(filepath.string)'", fallback: "attribute-based ID")
    
    let fallbackId = md5HashString(idString(for: filepath))
    
    do {
      let file = try FileHandle(forReadingFrom: filepath.fileURL)
      
      defer {
        file.closeFile()
      }

      let bufferSize: Int = 1024 * 1024
      let fileData = file.readData(ofLength: bufferSize)
      
      guard !fileData.isEmpty else {
        logger.emit(.warning, .modeled(failure.with(reason: "file is empty")))
        return fallbackId
      }
      
      return md5HashString(idString(for: filepath).data(using: .utf8)!, fileData)
    } catch {
      logger.emit(.error, .modeled(failure.with(error: error)))
      return fallbackId
    }
  }

  
  private static func md5HashString(_ input: String) -> String {
    var md5 = Insecure.MD5()
    md5.update(data: input.data(using: .utf8)!)
    return md5.finalize().hexString
  }
  
  
  private static func md5HashString(_ inputs: Data...) -> String {
    var md5 = Insecure.MD5()
    
    for data in inputs {
      md5.update(data: data)
    }

    return md5.finalize().hexString
  }
  
  /**
   * Derives a new ID string for a `FilePath`, using the path string and date created
   */
  private static func idString(for filepath: FilePath) -> String {
    let pathstring = filepath.string
    let created = filepath.creationDate ?? Date.now
    let fileTimeMilliseconds = Int64(created.timeIntervalSince1970 * 1000)
    
    return "\(pathstring):\(fileTimeMilliseconds)"
  }
  
  
  /**
   * Represents the different sources for generating new ContentIds
   *
   * - `attributes` - based on the file's absolute path at the time of indexing, and date created
   * - `content` - based on the file content (and date created)
   * - `random` - a random string identifier, used for files that are not yet indexed
   */
  enum ContentIdType: String, CaseIterable, Sendable {
    case attributes, filename, folder
    case content
    case random
    
    var idPrefix: String {
      switch self {
      case .attributes, .filename, .folder: return "filename"
      case .content: return "content"
      case .random: return "random"
      }
    }
    
    var resolvedType: Self {
      switch self {
      case .attributes, .filename, .folder: return .attributes
      case .content: return .content
      case .random: return .random
      }
    }
    
    init(rawValue: String) {
      let idType = ContentIdType.allCases.first { rawValue.starts(with: $0.rawValue) }
      self = idType?.resolvedType ?? .random
    }
  }
}


extension ContentId: CustomStringConvertible {
  var description: String { value }
}


extension ContentId: DatabaseValueConvertible {
  var databaseValue: DatabaseValue {
    DatabaseValue(value: self.value)!.databaseValue
  }

  static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
    guard let stringValue = String.fromDatabaseValue(dbValue) else {
      return nil
    }
    return ContentId(string: stringValue)
  }
}


extension Sequence where Element == ContentId {
 
  /// Returns an array of the string values of the ContentIds in the sequence.
  var values: [String] {
    self.map { $0.value }
  }
}
