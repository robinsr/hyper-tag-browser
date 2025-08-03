// created on 10/10/24 by robinsr

import CryptoKit
import Factory
import Foundation
import GRDB
import OSLog
import Regex
import System


extension ContentId {
  static let IDLength = 32
  static let IDPattern = #"^(filename|content|random):[\w\d]{\#(IDLength)}$"#
  static let IDRegex = try! Regex(string: IDPattern)
}



/**
 * A unique identifier used to identify content in the system.
 *
 * There are two types of IDs:
 * - `filename` - based on the file name and date created
 * - `content` - based on the file content
 *
 */
struct ContentId: Codable, Hashable, Equatable {
  static private let logger = EnvContainer.shared.logger("ContentId")
  
  /**
   * Represents the different sources for generating new ContentIds
   *
   * - `attributes` - based on the file's absolute path at the time of indexing, and date created
   * - `content` - based on the file content (and date created)
   * - `random` - a random string identifier, used for files that are not yet indexed
   */
  enum ContentIdType: String, CaseIterable {
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
   Creates a new ContentId not associated to a file URL using a random string identifier
   */
  static func newID() -> ContentId {
    .newID(using: .random, forURL: nil)
  }
  
  /**
   Manually specify the ID source for a new ContentId for the file at the given URL
   
   - If the source is `.filename` or `.folder`, the ID is based on the file or folder name.
   - If the source is `.content`, a hash of the file content is used.
   - If the source is `.random`, a random string identifier is used.
   */
  static func newID(using source: ContentIdType, forURL url: URL?) -> ContentId {
    var id: String
    
    switch source.resolvedType {
    case .attributes:
      id = Self.createFileAttributeHash(for: url!)
    case .content:
      id = Self.fileContentsBasedId(url!)
    case .random:
      id = .randomIdentifier(Self.IDLength)
    default:
      logger.emit(.warning, "Unhandled contentId generation source: \(source.rawValue). Falling back to random")
      
      id = .randomIdentifier(Self.IDLength)
    }
    
    return ContentId(string: "\(source.idPrefix):\(id)")
  }
  
  /**
   Determines the method for ID generation based on the type of file at the given URL
   
   - If the URL is a file, a hash of the file content is used.
   - If the URL is a directory, the ID is based on the directory name.
   */
  static func newID(forFile url: URL) -> ContentId {
    // TODO: !!! Support contents-based ID that accounts for duplicate files with different names !!!
    //
    // Currently, duplicating a file, specifically a contents-based ID type file,  will result in two content entries
    // files with identical contentIds, confusing the content indexer.
    //
    // For now, we will use the filename-based ID for all files.
    
    
    // var idType = IdSource.filename
    //
    // if url.isDirectory {
    //   idType = .folder
    // }
    //
    // if url.fileSize < Constants.maxFileSizeForContentId {
    //   idType = .content
    // }
    //
    // return .newID(using: idType, forURL: url)
    
    .newID(using: .attributes, forURL: url)
  }


  /**
   * Returns a string to use as input to the hash function for the file name
   */
  private static func fileAttributeHashInput(for url: URL) -> String {
    let filePath = FilePath(url.absoluteURL.formatted(.url.scheme(.never)))
    let fileDate = url.dateCreated.timeIntervalSince1970
    
    return "\(filePath):\(fileDate)"
  }

  /**
   * Generates a content-based ID for the file at the given URL.
   */
  private static func fileContentsBasedId(_ url: URL) -> String {
    let failure = ModeledError.failed(to: "create ContentID from file contents file: '\(url)'", fallback: "attribute-based ID")
    
    do {
      let file = try FileHandle(forReadingFrom: url)
      
      defer {
        file.closeFile()
      }

      let bufferSize: Int = 1024 * 1024
      let data = file.readData(ofLength: bufferSize)
      
      guard !data.isEmpty else {
        logger.emit(.warning, .modeled(failure.with(reason: "file is empty")))
        
        return createFileAttributeHash(for: url)
      }
      
      var md5 = CryptoKit.Insecure.MD5()
      
      // Using the file name hash as a prefix to the content hash to handle file duplicates
      md5.update(data: fileAttributeHashInput(for: url).data(using: .utf8)!)
      md5.update(data: data)
      
      return md5.finalize().hexString
    } catch {
      logger.emit(.warning, .modeled(failure.with(error: error)))
      
      return createFileAttributeHash(for: url)
    }
  }

  /**
   * Creates a ContentId based on the file path AND date created. This should account for
   * cases of file duplicate that would otherwise result in identical content-based IDs
   */
  private static func createFileAttributeHash(for url: URL) -> String {
    var md5 = Insecure.MD5()
    md5.update(data: fileAttributeHashInput(for: url).data(using: .utf8)!)
    return md5.finalize().hexString
  }
  
  
  /**
   A static ContentId that represents various "empty" scenarios
   */
  static let placeholder = ContentId(existing: Constants.noContentId)
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
