// created on 10/14/24 by robinsr

import CoreTransferable
import CustomDump
import Foundation
import GRDB
import GRDBQuery
import JulianDayNumber
import System
import UniformTypeIdentifiers


private typealias Indx = IndexRecord
private typealias IndxCol = IndexRecord.Columns

struct IndexRecord: Identifiable, Equatable, Hashable, FileSystemContentItem, IdentifiableContentItem {
  var id: ContentId
  var timestamp: Date
  var name: String
  @CodableFilePath var location: FilePath
  var volume: String
  var type: UTType
  var size: Int
    // The date the file was created. Date is persisted as UTC date, you must convert to local time.
  var created: Date
  var modified: Date
  var comment: String
  var visibility: ContentItemVisibility
  
  
  // Virtual Columns
  var fileExists: Bool?
  var isIndexed: Bool = true
  
  var exists: Bool {
    FileManager.default.fileExists(atPath: filepath.string)
  }
  
  var pointer: ContentPointer {
    .init(id: self.id, filePath: self.filepath)
  }

  var url: URL {
    location.appending(name).fileURL
  }
  
  var filepath: FilePath {
    location.appending(name)
  }
  
  var isFolder: Bool {
    type.conforms(to: .folder)
  }
  
  var julianCreated: JulianDate {
    created.julianDate
  }
  
  var julianModified: JulianDate {
    modified.julianDate
  }
  
  var link: Route {
    pointer.link
  }
  
  var contentId: ContentId {
    self.id
  }
  
  func conforms(to: UTType) -> Bool {
    type.conforms(to: to)
  }
  
    /// Returns a `ContentItem` representation of this `IndexRecord`, adding the provided tags and queues.
  func asContentItem(tags: [IndexTagValueRecord] = [], queues: [QueueItemRecord] = []) -> ContentItem {
    IndexInfoRecord(index: self, tagValues: tags, queueItems: queues)
  }
  
  func isIndexed(db: Database) throws -> Bool {
    try Self.exists(db, id: contentId)
  }
  
  func renameTask(for update: IndexRecord.Update) -> RenameTask? {
    if let newName = update.filename {
      return .init(contentId: id, previous: filepath, updated: location.appending(newName))
    }
    
    if let newFolder = update.location {
      return .init(contentId: id, previous: filepath, updated: newFolder.appending(name))
    }
    
    return nil
  }
}


extension IndexRecord: TableRecord, PersistableRecord {
  static let databaseTableName = "app_content_indices"

  static let tagValues = hasMany(IndexTagValueRecord.self, using: .toThis(from: "contentId"))
  
  static let tags = hasMany(TagRecord.self, through: tagValues, using: IndexTagValueRecord.associatedTag)
  
  static let tagstring = hasOne(TagstringRecord.self, using: .toThis(from: "contentId"))
  
  static let queueItems = hasMany(QueueItemRecord.self)
  
  static let queues = hasMany(QueueRecord.self, through: queueItems, using: QueueItemRecord.queue)
  
  static let bookmark = hasOne(BookmarkRecord.self, using: .toThis(from: "contentId"))
  
  struct Associates {
    static let tags = IndexRecord.tags
    static let tagstring = IndexRecord.tagstring.aliased(TableAliases.tagstring)
  }
  
  struct TableAliases {
    static let tagstring = TableAlias()
    static let tagCount = tagstring[TagstringRecord.Columns.tagCount ?? 0]
  }
  
  struct Selections {
    static var fileURL: SQLExpression {
      DatabaseFunctions.concat(Columns.location, Columns.name)
    }
    
    /// `file_exists` optionally takes 2 args: `location` (directory) and `name` (filename) and resolves the path
    static var fileExists: SQLExpression {
      DatabaseFunctions.fileExistsIn.call(Columns.location, Columns.name)
    }
    
    static var fileXID: SQLExpression {
      DatabaseFunctions.xattr.call(Selections.fileURL, Constants.xContentIdKey)
    }
    
    static var tagCount: SQLExpression {
      TableAliases.tagCount
    }
    
    /*
     * INSTR(string, substring); - returns integer position of the substring, which is the first character of the substring
     * SUBSTR( string, start, length ) - returns a substring of the string, starting at position `start` and with length `length`.
     */
    
    static var cachePath: SQLExpression {
      AppLocation.caches.string.sqlExpression
    }

    static func conforms(to uttype: UTType) -> SQLExpression {
      DatabaseFunctions.conformsTo.call(Columns.type, uttype)
    }
  }
}

extension IndexRecord: Codable {
  
    /// Codingkeys represent the mutable column tables in the database.
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id, timestamp, name, location, volume, type, size, created, modified, comment, visibility
  }
  
  enum Columns: String, ColumnExpression, CaseIterable {
    case id, timestamp, name, location, volume, type, size, created, modified, comment, visibility
    
    static var allColumns: [SQLSelectable] {
      allCases.map(\.sqlSelection)
    }
  }
   
  enum VirtualColumns: String, ColumnExpression, CaseIterable {
      /// Generated columns, not stored in the database.
    case url, fileExists, isFolder
    
    var name: String { rawValue }
    
    var sqlExpression: SQLExpression {
      switch self {
      case .url:
        Selections.fileURL
      case .isFolder:
        Selections.conforms(to: .folder)
      case .fileExists:
        Selections.fileExists
      }
    }
    
    var sqlSelection: SQLSelection {
      sqlExpression.sqlSelection
    }
    
    static var allColumns: [SQLSelectable] {
      allCases.map(\.sqlSelection)
    }
  }
  
  static var allColumns: [SQLSelectable] {
    Columns.allColumns + VirtualColumns.allColumns
  }
}


extension DerivableRequest<IndexRecord> {
  private typealias Indx = IndexRecord
  private typealias Cols = IndexRecord.Columns
  
  private typealias InfoCols = IndexInfoRecord.CodingKeys
  
  
  func withContentId(_ id: ContentId) -> Self {
    filter(Indx.Columns.id == id)
  }
  
  func withContentId(_ ids: [ContentId]) -> Self {
    filter(Indx.Columns.id.in(ids))
  }
  
  func withContentType(_ uttype: UTType) -> Self {
    filter(Indx.Selections.conforms(to: uttype))
  }
  
  /**
   Modifies the request to include the `tagValues` associations (`IndexTagValueRecord`).
   */
  func joiningTagValues() -> Self {
    including(all: Indx.tagValues.forKey(InfoCols.tagValues))
  }
  
  /**
   Joins `TagstringRecord` to the request, and selects the `tagCount` column.
   */
  func joiningTagCount() -> Self {
    joining(optional: Indx.Associates.tagstring.forKey(InfoCols.tagCount))
  }

  /**
    Modifies the request to include the `queueItems` associations (`QueueItemRecord`).
   */
  func joiningQueueItems() -> Self {
    including(all: Indx.queueItems.forKey(InfoCols.queueItems))
  }
}


extension IndexRecord {  
  static func distinctLocations() -> QueryInterfaceRequest<FilePath> {
    IndexRecord
      .all()
      .distinct()
      .select(Columns.location)
      .group(Columns.location)
  }
  
  static func lostFiles() -> QueryInterfaceRequest<IndexRecord> {
    IndexRecord
      .all()
      .filter(!Selections.fileExists)
  }
}




extension IndexRecord: EncodableRecord {
  /**
   Encodes only those columns that are actually in the table.
   
   I'm not sure if GRDB has a better way of creating virtual/generated columns
   that do not rely on database funtions. If found, this extension could be removed.
   */
  func encode(to container: inout PersistenceContainer) throws {
    container["id"] = id
    container["name"] = name
    container["location"] = location
    container["volume"] = volume
    container["type"] = type
    container["size"] = size
    container["created"] = created
    container["modified"] = modified
    container["comment"] = comment
    container["visibility"] = visibility.rawValue
    container["timestamp"] = timestamp
  }
}


extension IndexRecord: FetchableRecord {
  
  /**
   The primary initializer, creates a new `IndexRecord` from a file URL. If the
   contentId is known (so we're not creating a new record), it can be passed in.
   */
  init(path: FilePath, contentId: ContentId) throws {
    
    let attributes: FilePath.Attributes = try path.attributes()
    
    
    self.id = contentId // ?? ContentId.newID(forFile: path.fileURL)
    self.timestamp = Date.now
    self.name = path.baseName
    self.location = path.directory
    self.volume = path.fileURL.volumeInfo?.name ?? VolumeInfo.defaultName
    self.type = path.fileURL.contentType
    self.size = Int(attributes.size ?? 0)
    self.visibility = .normal
    self.created = attributes.creationDate ?? .distantPast
    self.modified = attributes.modificationDate ?? .distantPast

    let metadata = FileMetadata(fileURL: path.fileURL)
    self.comment = metadata.exifComment ?? metadata.exifDump
  }
  
  init(fileURL url: URL, contentId: ContentId) throws {
    try self.init(path: url.filepath, contentId: contentId)
  }
  
  // Does IndexRecord need a custom Decoder in order to get virtual/generated columns?
  
  /**
   An initializer that creates a new `IndexRecord` from a `Row` object. Used by GRDB for
   object creation. Can be used in other contexts as well (such as from spotlight search
   CSAttribute objects).
   
   This initializer is needed because GRDB does not automatically populated the virtual/generated columns
   with values from the database.
   */
  init(row: Row) {
    self.id = row[Columns.id]
    self.timestamp = row[Columns.timestamp]
    self.name = row[Columns.name]
    self.location = row[Columns.location]
    self.volume = row[Columns.volume]
    self.type = row[Columns.type]
    self.size = row[Columns.size]
    self.created = row[Columns.created]
    self.modified = row[Columns.modified]
    self.comment = row[Columns.comment]
    self.visibility = ContentItemVisibility(rawValue: row[Columns.visibility]) ?? .normal
    // Virtual Columns
    self.fileExists = row[VirtualColumns.fileExists]
    self.isIndexed = row["isIndexed"] ?? true
  }
}

extension IndexRecord: Transferable {
  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .json)
  }
}

extension Collection where Element == IndexRecord {
  var string: String {
    self.map(\.contentId.value).joined(separator: ", ")
  }
  
  var ids: [ContentId] {
    self.map(\.contentId)
  }
  
  var pointers: [ContentPointer] {
    self.map(\.pointer)
  }
  
  subscript(path: FilePath) -> IndexRecord? {
    self.first { $0.filepath == path }
  }
}
