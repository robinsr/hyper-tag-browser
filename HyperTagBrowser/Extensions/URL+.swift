// created on 9/27/24 by robinsr

import Files
import Foundation
import OSLog
import Regex
import System
import UniformTypeIdentifiers


extension URL {
  static func +(lhs: URL, rhs: String) -> URL {
    lhs.appendingPathComponent(rhs)
  }
}

extension URL {
  
  /**
   Returns a `Files.Folder` object for the URL if it exists.
   */
  var folder: Folder? {
    try? Folder(path: path(percentEncoded: true))
  }
  
  
  /**
   Returns a `Files.File` object for the URL if it exists.
   */
  var file: File? {
    try? File(path: path(percentEncoded: true))
  }
}


extension URL {
  
  private var fm: FileManager {
    FileManager.default
  }
  
  /**
   By self-convention, this URL value is considered to be equivalent to `nil`.
   */
  static var null: URL {
    URL(fileURLWithPath: "/dev/null", isDirectory: true)
  }
  
  /**
   Returns true if the URL is equivalent to the "null" URL value (/dev/null/).
   */
  var isNull: Bool {
    self == Self.null
  }
  
  var isDirectory: Bool {
     boolResourceValue(forKey: .isDirectoryKey, defaultValue: false)
  }
  
  /**
   Returns an equivalent URL without the last path component. Typically this is the containing directory.
   */
  var directoryURL: Self {
    deletingLastPathComponent()
  }
  
  /**
   Returns an equivalent URL string without the last path component. Typically this is the containing directory.
   */
  var directory: String { directoryURL.path }
  
  
  var filepath: FilePath {
    FilePath(self.absoluteURL.formatted(.url.scheme(.never)))
  }
  
  var debugDescription: String {
    """
    URL(
      filepath: \(filepath)
      absoluteURL: \(absoluteURL)
      absoluteString: \(absoluteString)
      path: \(path)
      directory: \(directory)
      filename: \(filename)
      fileExtension: \(fileExtension)
      fileSize: \(fileSize)
      isNull: \(isNull)
    )
    """
  }
  
  var filename: String {
    lastPathComponent
  }
  
  var fileExtension: String {
    pathExtension
  }
  
  var filenameWithoutExtension: String {
    deletingPathExtension().lastPathComponent
  }
  
  func resourceValue<T>(forKey key: URLResourceKey) -> T? {
    guard fm.fileExists(atPath: self.filepath.string) else { return nil }
    
    do {
      let values = try resourceValues(forKeys: [key])
      return values.allValues[key] as? T
    } catch {
      print("Failed to get value for URLResourceKey '\(key)' for url \(self.filepath.string): \(error.localizedDescription)")
      return nil
    }
  }
  
  func boolResourceValue(forKey key: URLResourceKey, defaultValue: Bool = false) -> Bool {
    guard fm.fileExists(atPath: self.filepath.string) else { return defaultValue }
    
    guard let values = try? resourceValues(forKeys: [key]) else {
      print("Failed to get resource values for URLResourceKey: \(key)")
      return defaultValue
    }
    
    return values.allValues[key] as? Bool ?? defaultValue
  }
  
  var hasExtendedAttributes: Bool {
    boolResourceValue(forKey: .mayHaveExtendedAttributesKey)
  }
  
    /// Returns the UTType of the file.
  var contentType: UTType {
    resourceValue(forKey: .contentTypeKey) ?? .item
  }
  
  var fileAttributes: [FileAttributeKey: Any]? {
    do {
      return try fm.attributesOfItem(atPath: filepath.string)
    } catch {
      print("Error getting file attributes for \(filepath): \(error)")
      return nil
    }
  }
  
  var systemFileNumber: Int64 {
    fileAttributes?[.systemFileNumber] as? Int64 ?? 0
  }
  
  /// "File System Number"
  var systemNumber: Int64 {
    fileAttributes?[.systemNumber] as? Int64 ?? 0
  }
  
  var fileNumber: Int64 {
    resourceValue(forKey: .fileIdentifierKey) ?? 0
  }
  
  var systemFileIdentifier: String { "\(systemFileNumber)" }
  var systemIdentifier: String { "\(systemNumber)" }
  var fileIdentifier: String { "\(fileNumber)" }


    /// Returns the file size in bytes.
  var fileSize: Int {
    resourceValue(forKey: .fileSizeKey) ?? 0
  }
  
  var dateCreated: Date {
    try! filepath.attributes().creationDate ?? .distantPast
  }
  
  func isParent(of item: URL) -> Bool {
    appendingPathComponent(item.filename) == item
  }
  
  func isChild(of parent: URL) -> Bool {
    parent.appendingPathComponent(filename) == self
  }
  
  func isDescendant(of ancestor: URL) -> Bool {
    filepath.starts(with: ancestor.filepath)
  }
  
  func startsWith(_ other: URL) -> Bool {
    filepath.starts(with: other.filepath)
  }
  
  /**
   Returns a new URL maintaining the original's filename but with the given directory.
   */
  func asRelocated(to destination: URL) -> URL {
    destination.appendingPathComponent(lastPathComponent)
  }
  
  /*
    Returns a new URL with either the filename appended to the URL or replacing the existing filename.
   */
  func withFilename(_ filename: String) -> URL {
    let location = isDirectory ? deletingLastPathComponent() : self
    
    return location.appending(path: filename, directoryHint: .notDirectory)
  }
  
  func shiftAncestor(from ancestor: URL, to destination: URL) -> URL {
    let newPath = path.replacingOccurrences(of: ancestor.path, with: destination.path)
    
    return URL(fileURLWithPath: newPath)
  }

  var components: URLComponents? {
    URLComponents(url: self, resolvingAgainstBaseURL: true)
  }
  
  func relationship(to url: Self) -> FileManager.URLRelationship {
    var relationship: FileManager.URLRelationship = .other
    _ = try? FileManager.default.getRelationship(&relationship, ofDirectoryAt: self, toItemAt: url)
    return relationship
  }
}
