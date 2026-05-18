// created on 4/1/25 by robinsr

import CustomDump
import Foundation
import System


extension FilePath {
  
  //
  // MARK: - Public Type Properties
  //

  public static var currentDirectory: FilePath {
    get { .init(FileManager.default.currentDirectoryPath) }
    set { FileManager.default.changeCurrentDirectoryPath(newValue.string) }
  }
  
  /**
   * A internal convention; a FilePath that this project considers equivalent to `nil`.
   */
  public static var null: FilePath {
    URL.null.filepath
  }
  
  
  //
  // MARK: - Instance Properties
  //
  
  /// A semi-unique identifier for the file, derived from its base name
  public var shortID: String {
    String(baseName.unicodeScalars.filter(CharacterSet.alphanumerics.inverted.contains))
  }
  
  /// The parent directory
  public var directory: FilePath {
    FilePath((string as NSString).deletingLastPathComponent)
  }

  /// The `URL` representation of this FilePath
  public var fileURL: URL {
    if #available(macOS 13.0, iOS 16.0, *) {
      URL(filePath: self)!  // swiftlint:disable:this force_unwrapping
    } else {
      URL(self)!  // swiftlint:disable:this force_unwrapping
    }
  }

  public func attributes() throws -> Attributes {
    FilePath.Attributes(try FileManager.default.attributesOfItem(atPath: string))
  }

  public func componentsToDisplay() -> [String]? {
    FileManager.default.componentsToDisplay(forPath: string)
  }
  
  public func displayName() -> String {
    FileManager.default.displayName(atPath: string)
  }
  
  /// Either the directory name or the filename (with file extension)
  public var baseName: String {
    (string as NSString).lastPathComponent
  }
  
  public var creationDate: Date? {
    try? attributes().creationDate
  }
  
  
  //
  // MARK: - Assertions
  //

  /// True if the path is equal to the `.null` path.
  public var isNull: Bool {
    self == Self.null
  }
  
  public var isDirectory: Bool {
    fileURL.contentType.conforms(to: .folder)
  }

  public var isDeletable: Bool {
    FileManager.default.isDeletableFile(atPath: string)
  }

  public var isExecutable: Bool {
    FileManager.default.isExecutableFile(atPath: string)
  }

  public var isReadable: Bool {
    FileManager.default.isReadableFile(atPath: string)
  }

  public var isWritable: Bool {
    FileManager.default.isWritableFile(atPath: string)
  }
  
  public var isBrowsable: Bool {
    FileManager.default.directoryExists(atPath: string)
  }
  
  public var exists: Bool {
    FileManager.default.fileExists(atPath: string)
  }
  
  
  //
  // MARK: - Mutate FilePath
  //


  public mutating func abbreviateWithTilde() {
    self = abbreviatingWithTilde()
  }

  public func abbreviatingWithTilde() -> FilePath {
    FilePath((string as NSString).abbreviatingWithTildeInPath)
  }

  public mutating func appendExtension(_ ext: String) {
    self = appendingExtension(ext)
  }

  public func appendingExtension(_ ext: String) -> FilePath {
    guard let result = (string as NSString).appendingPathExtension(ext)
    else { return self }

    return FilePath(result)
  }

  public func expandingTilde() -> FilePath {
    FilePath((string as NSString).expandingTildeInPath)
  }

  public mutating func expandTilde() {
    self = expandingTilde()
  }
  
  public func removingPrefix(_ prefix: FilePath) -> FilePath {
    var copy = self
    let removed = copy.removePrefix(prefix)
    
    return removed ? copy : self
  }

  public mutating func removeExtension() {
    self = removingExtension()
  }

  public func removingExtension() -> FilePath {
    FilePath((string as NSString).deletingPathExtension)
  }

  public mutating func replaceExtension(with ext: String) {
    self = replacingExtension(with: ext)
  }

  public func replacingExtension(with ext: String) -> FilePath {
    let stripped = (string as NSString).deletingPathExtension

    guard let result = (stripped as NSString).appendingPathExtension(ext)
    else { return self }

    return FilePath(result)
  }

  public mutating func resolveSymbolicLinks() {
    self = resolvingSymbolicLinks()
  }

  public func resolvingSymbolicLinks() -> FilePath {
    FilePath((string as NSString).resolvingSymlinksInPath)
  }

  public mutating func standardize() {
    self = standardizing()
  }

  public func standardizing() -> FilePath {
    FilePath((string as NSString).standardizingPath)
  }
  
  public func relative(to path: FilePath) -> FilePath {
    let cwd = self.string
    let dest = path.string
    
    guard cwd.starts(with: dest) else {
        return path
    }
    
    let index = cwd.index(cwd.startIndex, offsetBy: dest.count)
    
    return FilePath(String(cwd[index...]).removingSuffix("/"))
  }
  
  @available(*, deprecated, renamed: "relative(to:)", message: "Use `relative(to:)` instead.")
  public func path(relativeTo base: FilePath) -> FilePath {
    relative(to: base)
  }
  
  
  //
  // MARK: - Sub-contents
  //
  
  /// Returns true if this FilePath is a directory that contains other
  @available(*, deprecated, message: "Unused as of 2026-01-12")
  public func contains(_ other: FilePath) -> Bool {
    if !isDirectory {
      return false
    }
    
    return other.starts(with: self)
  }

  @available(*, deprecated, message: "Unused as of 2026-01-12")
  public func subcontents(
    propertyKeys keys: [URLResourceKey]? = nil,
    options: FileManager.DirectoryEnumerationOptions = []
  ) throws -> [FilePath] {
    try FileManager.default.contentsOfDirectory(
      at: fileURL,
      includingPropertiesForKeys: keys,
      options: options
    ).map {
      FilePath($0.path)
    }
  }
  
  
  //
  // MARK: - Creating
  //

  public func createDirectory(
    andPath createIntermediates: Bool = true,
    attributes: Attributes? = nil
  ) throws {
    try FileManager.default.createDirectory(
      at: fileURL,
      withIntermediateDirectories: createIntermediates,
      attributes: attributes?.dictionaryRepresentation)
  }

  public func createFile(
    contents: Data? = nil,
    attributes: Attributes? = nil
  ) -> Bool {
    FileManager.default.createFile(
      atPath: string,
      contents: contents,
      attributes: attributes?.dictionaryRepresentation)
  }

  public func createSymbolicLink(to destination: FilePath) throws {
    try FileManager.default.createSymbolicLink(
      at: fileURL,
      withDestinationURL: destination.fileURL)
  }

  public func destinationOfSymbolicLink() throws -> FilePath {
    let dstPath = FilePath(try FileManager.default.destinationOfSymbolicLink(atPath: string))

    if dstPath.isAbsolute {
      return dstPath
    }

    return appending("..").pushing(dstPath)
  }
  
  
  //
  // MARK: Copy/Move/Link/Delete
  //
  
  public func copy(to destination: FilePath) throws {
    try FileManager.default.copyItem(
      at: fileURL,
      to: destination.fileURL)
  }

  public func link(to destination: FilePath) throws {
    try FileManager.default.linkItem(
      at: fileURL,
      to: destination.fileURL)
  }

  public func move(to destination: FilePath) throws {
    try FileManager.default.moveItem(
      at: fileURL,
      to: destination.fileURL)
  }

  public func remove() throws {
    try FileManager.default.removeItem(at: fileURL)
  }

  public func replace(
    with replacement: FilePath,
    backup: FilePath? = nil,
    usingNewMetaDataOnly: Bool = false,
    withoutDeletingBackupItem: Bool = false
  ) throws -> FilePath {
    var options: FileManager.ItemReplacementOptions = []

    if usingNewMetaDataOnly {
      options.formUnion(.usingNewMetadataOnly)
    }

    if withoutDeletingBackupItem {
      options.formUnion(.withoutDeletingBackupItem)
    }

    var resultURL: NSURL?

    try FileManager.default.replaceItem(
      at: fileURL,
      withItemAt: replacement.fileURL,
      backupItemName: backup?.string,
      options: options,
      resultingItemURL: &resultURL)

    return FilePath(resultURL?.path ?? "")
  }

  public func setAttributes(_ attributes: Attributes) throws {
    try FileManager.default.setAttributes(
      attributes.dictionaryRepresentation,
      ofItemAtPath: string)
  }
}


extension FilePath: @retroactive CustomDumpStringConvertible {
  public var customDumpDescription: String {
    string
  }
}


extension Collection where Element == FilePath {
  
  /**
   * Returns true if `other` starts with a path contained in this set
   */
  func contains(startOf other: FilePath) -> Bool {
    self.contains { other.starts(with: $0) }
  }
}
