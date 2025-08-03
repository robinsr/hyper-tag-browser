// created on 4/1/25 by robinsr

import CustomDump
import Foundation
import System


extension FilePath {
  
  /**
   * A internal convention; a FilePath that this project considers equivalent to `nil`.
   */
  static var null: FilePath {
    URL.null.filepath
  }
  
  /**
   * True if the path is equal to the `.null` path.
   */
  var isNull: Bool {
    self == Self.null
  }

  public var baseName: String {
    (string as NSString).lastPathComponent
  }
  
  /**
   * A semi-unique identifier for the file, derived from its base name.
   */
  public var shortID: String {
    String(baseName.unicodeScalars.filter(CharacterSet.alphanumerics.inverted.contains))
  }
  
  public var directory: FilePath {
    FilePath((string as NSString).deletingLastPathComponent)
  }
  
  public var isDirectory: Bool {
    fileURL.contentType.conforms(to: .folder)
  }

  public var fileURL: URL {
    if #available(macOS 13.0, iOS 16.0, *) {
      URL(filePath: self)!  // swiftlint:disable:this force_unwrapping
    } else {
      URL(self)!  // swiftlint:disable:this force_unwrapping
    }
  }

  // MARK: Public Instance Methods

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
  
  public func path(relativeTo base: FilePath) -> FilePath {
    guard starts(with: base) else {
        return base
    }

    let index = string.index(string.startIndex, offsetBy: base.string.count)
    return FilePath(String(string[index...]).removingSuffix("/"))
  }
  
  // MARK: Public Type Properties

  public static var currentDirectory: FilePath {
    get { .init(FilePath.fileManager.currentDirectoryPath) }
    set { FilePath.fileManager.changeCurrentDirectoryPath(newValue.string) }
  }

  // MARK: Public Instance Methods

  public func attributes() throws -> Attributes {
    .init(try FilePath.fileManager.attributesOfItem(atPath: string))
  }

  public func componentsToDisplay() -> [String]? {
    FilePath.fileManager.componentsToDisplay(forPath: string)
  }

  public func contentsOfDirectory(
    includingPropertiesForKeys keys: [URLResourceKey]? = nil,
    options: FileManager.DirectoryEnumerationOptions = []
  ) throws -> [FilePath] {
    try FilePath.fileManager.contentsOfDirectory(
      at: fileURL,
      includingPropertiesForKeys: keys,
      options: options
    ).map {
      FilePath($0.path)
    }
  }

  public func copy(to destination: FilePath) throws {
    try FilePath.fileManager.copyItem(
      at: fileURL,
      to: destination.fileURL)
  }

  public func createDirectory(
    withIntermediateDirectories createIntermediates: Bool = true,
    attributes: Attributes? = nil
  ) throws {
    try FilePath.fileManager.createDirectory(
      at: fileURL,
      withIntermediateDirectories: createIntermediates,
      attributes: attributes?.dictionaryRepresentation)
  }

  public func createFile(
    contents: Data? = nil,
    attributes: Attributes? = nil
  ) -> Bool {
    FilePath.fileManager.createFile(
      atPath: string,
      contents: contents,
      attributes: attributes?.dictionaryRepresentation)
  }

  public func createSymbolicLink(to destination: FilePath) throws {
    try FilePath.fileManager.createSymbolicLink(
      at: fileURL,
      withDestinationURL: destination.fileURL)
  }

  public func destinationOfSymbolicLink() throws -> FilePath {
    let dstPath = FilePath(try FilePath.fileManager.destinationOfSymbolicLink(atPath: string))

    if dstPath.isAbsolute {
      return dstPath
    }

    return appending("..").pushing(dstPath)
  }

  public func displayName() -> String {
    FilePath.fileManager.displayName(atPath: string)
  }

  public func exists() -> Bool {
    FilePath.fileManager.fileExists(atPath: string)
  }

  public func isDeletable() -> Bool {
    FilePath.fileManager.isDeletableFile(atPath: string)
  }

  public func isExecutable() -> Bool {
    FilePath.fileManager.isExecutableFile(atPath: string)
  }

  public func isReadable() -> Bool {
    FilePath.fileManager.isReadableFile(atPath: string)
  }

  public func isWritable() -> Bool {
    FilePath.fileManager.isWritableFile(atPath: string)
  }
  
  public func isBrowsable() -> Bool {
    FilePath.fileManager.directoryExists(atPath: string)
  }

  public func link(to destination: FilePath) throws {
    try FilePath.fileManager.linkItem(
      at: fileURL,
      to: destination.fileURL)
  }

  public func move(to destination: FilePath) throws {
    try FilePath.fileManager.moveItem(
      at: fileURL,
      to: destination.fileURL)
  }

  public func remove() throws {
    try FilePath.fileManager.removeItem(at: fileURL)
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

    try FilePath.fileManager.replaceItem(
      at: fileURL,
      withItemAt: replacement.fileURL,
      backupItemName: backup?.string,
      options: options,
      resultingItemURL: &resultURL)

    return FilePath(resultURL?.path ?? "")
  }

  public func setAttributes(_ attributes: Attributes) throws {
    try FilePath.fileManager.setAttributes(
      attributes.dictionaryRepresentation,
      ofItemAtPath: string)
  }

  // MARK: Private Type Properties

  private static var fileManager: FileManager = .default
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
