// created on 9/2/24 by robinsr

import Factory
import Files
import OrderedCollections
import OSLog
import Regex
import System
import UniformTypeIdentifiers
import ZipArchive


/**
 * Provides for listing contents of local filesytem directories
 *
 * This service provides methods to list directories, subfolders, and files, renaming files,
 * moving files to the trash, creating directories, and more.
 *
 * It also supports monitoring file system changes via NotificationCenter observers
 * for content renaming and relocation events.
 *
 * Usage:
 *
 * ```swift
 * let fileService = LocalFileService(monitoring: true)
 *
 * let subfolders = fileService.subfolders(of: someDirectoryURL)
 * let tree = fileService.tree(at: someDirectoryURL, depth: 2)
 *
 * do {
 *     try fileService.rename(someFileURL, to: newFileURL)
 * } catch {
 *     print("Error renaming file: \(error.localizedDescription)")
 * }
 * ```
 */
final class LocalFileService {
  typealias Errors = LocalFileServiceError
  
  private let fm = FileManager()
  private let logger = EnvContainer.shared.logger("LocalFileService")
  
  private let cache = Container.shared.fileCache()
  
  @Injected(\.metadataService) private var metadata
  
  init(monitoring: Bool = false) {
    
    if monitoring {
      logger.emit(.info, "Enabling NotificationCenter observers: .contentWasRenamed, .contentWasRelocated")
      
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(self.onContentRenamed),
        name: .contentWasRenamed,
        object: nil
      )
      
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(self.onContentRenamed),
        name: .contentWasRelocated,
        object: nil
      )
    }
  }
  
  @objc func onContentRenamed(_ notification: Notification) {
    if let task = notification.object as? RenameTask {
      logger.dump(task, label: "RenameTask received")
      
      do {
        try rename(task.previous, to: task.updated)
      } catch {
        logger.error("Error renaming file: \(error.localizedDescription)")
      }
    }
  }
  
  
  /**
   * Resets the cache for the specified directory.
   *
   * - Parameter dir: The URL of the directory for which to reset the cache.
   *
   * This function evicts all cached items that match the specified directory URL.
   */
  func resetCache(forDirectory dir: URL) {
    cache.evictBy(matchingURL: dir)
  }
  
  
  /**
   * Returns a list of URLs of subfolders in the specified directory.
   *
   * - Parameter url: The URL of the directory for which to list subfolders.
   *
   * This function uses the `Files` library to retrieve subfolders, handling errors gracefully
   * and logging them if they occur.
   *
   * - Returns: An array of URLs representing the subfolders in the specified directory.
   */
  func subfolders(of url: URL) -> [URL] {
    do {
      return try Folder(path: url.filepath.string).subfolders.map(\.url)
    } catch {
      logger.emit(.error, ErrorMsg("Error listing subfolders of \(url.filepath)", error))
      return []
    }
  }
  
  
  /**
   * Returns a list of URLs of subfolders adjacent to the specified URL.
   *
   * - Parameter url: The URL of the directory for which to find adjacent subfolders.
   *
   * This function checks the parent directory of the given URL and returns all subfolders
   * in that parent directory, excluding the specified URL itself.
   *
   * - Returns: An array of URLs representing adjacent subfolders.
   */
  func adjacent(to url: URL) -> [URL] {
    let container = url.directoryURL
    
    guard container != url && container.filepath != "/" else {
      return []
    }
    
    return subfolders(of: container).filter { $0 != url }
  }
  
  
  /**
   * Returns a `FileTreeNode` representing the directory tree at the specified URL.
   *
   * - Parameters:
   *   - url: The URL of the directory to represent as a tree.
   *   - remaining: The depth to which subdirectories should be explored (default is 0, meaning no subdirectories).
   *
   * This function constructs a tree structure where each node represents a directory,
   * and leaf nodes represent files. If `remaining` is greater than 0, it will recursively
   * explore subdirectories up to the specified depth.
   */
  func tree(at url: URL, depth remaining: Int = 0) -> FileTreeNode {
    FileTreeNode(
      path: url.filepath,
      children: listURLs(at: url, mode: .immediate(), types: .folders).map {
        if $0.isDirectory && remaining > 0 {
          return tree(at: $0, depth: remaining - 1)
        } else {
          return FileTreeNode(path: $0.filepath)
        }
      }
    )
  }
  
  
  /**
   * Returns a `FileTreeNode` representing the branch from `root` to `dest`.
   *
   * - Parameters:
   *   - root: The root directory from which the branch starts.
   *   - dest: The destination file path to which the branch leads.
   *
   * This function constructs a tree structure where each node represents a directory
   * in the path from `root` to `dest`. The leaf node is the `dest` itself.
   */
  func branch(from root: FilePath, to dest: FilePath) -> FileTreeNode {
    let steps = dest.path(relativeTo: root).components.collect()
    
    let paths = steps.indexed.map { index, step in
      
      let path = steps[0..<index]
        .map(\.string)
        .joined(separator: "/")
      
      return root.appending(path)
    }

    var targetNode = FileTreeNode(path: dest, children: [])
    
    for path in paths.reversed() {
      targetNode = FileTreeNode(path: path, children: [targetNode])
    }
    
    return targetNode
  }
  
  
  /**
   * Finds subfolders in a given directory that match the specified text.
   *
   * - Parameters:
   *   - root: The root directory to search within.
   *   - text: The text to match against folder names.
   *   - count: The maximum number of matching folders to return (default is 5).
   *
   * - Returns: An array of `FilePath` objects representing the matching folders.
   */
  func findFolder(from root: FilePath, matching text: String, count: Int = 5) throws -> [FilePath] {
    guard text.count > 2 else { return [] }
    
    do {
      let pattern = try Regex(string: text, options: .ignoreCase)
      
        // TODO: Very poor performance when there are many subfolders (such as from user home)
      return try Folder(path: root.string)
        .subfolders
        .recursive
        .filter { pattern.matches($0.name) }
        .prefix(count)
        .map(\.url.filepath)
        .collect()
      
    } catch {
      logger.emit(.error, ErrorMsg("Error listing subfolders of \(root.string)", error))
      return []
    }
  }
  
  
  /**
   * Lists all URLs in a given directory, filtering by the specified content types.
   *
   * - Parameters:
   *   - folder: A `URL` for the location of a local filesystem directory
   *   - mode: Preconfigured listing mode from `ListMode`
   *   - types: Preconfigured set of types from `AllowedFileTypes`
   *   - keys: Preconfigured set of `URLResourceKeys` to prefetch into file URLs from `PrefetchAttributes`
   *
   * - Returns: An array of `URL`s that match the specified content types.
   */
  func listURLs(
    at folder: URL,
    mode: ListMode = .immediate(),
    types: ContentTypeGroup = .folders,
    keys: URLResourceKeySet = .basic
  ) -> [URL] {
    let listOpts = mode.forURL(folder)
    let resourceKeys = keys.resourceKeys
    let contents = fm.enumerator(at: folder, includingPropertiesForKeys: resourceKeys, options: listOpts)!
    var urls = [URL]()
    
    while let fileURL = autoreleasepool(invoking: { contents.nextObject() }) as? URL {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
            let fileType = resourceValues.contentType
      else {
        logger.emit(.warning, "Error getting the file \(fileURL.lastPathComponent)")
        continue
      }
      
      if types.allows(filetype: fileType) {
        urls.append(fileURL)
      }
    }
    
    return urls
  }
  
  
  /**
   * Returns a `ContentPointerURLMapping` of all the content items in a given directory that have
   * a contentId extended attribute value.
   *
   * - Parameters:
   *   - folder: A `URL` for the location of a local filesystem directory
   *   - mode: Preconfigured listing mode from `ListMode`
   *   - types: Preconfigured set of types from `AllowedFileTypes`
   *   - keys: Preconfigured set of `URLResourceKeys` to prefetch into file URLs from `PrefetchAttributes`
   */
  func listIndexedContents(
    of folder: URL,
    mode: ListMode,
    types: ContentTypeGroup,
    keys: URLResourceKeySet = .basic
  ) -> ContentPointerURLMapping {
    
    let cachekey = LocalFileCache.CacheKey(dir: folder, mode: mode, types: types.filetypeIdentifiers.joined())
    
    if let cachedResult = cache.get(forParams: cachekey) {
      return cachedResult.items
    }
    
    let listOpts = mode.forURL(folder)
    let resourceKeys = keys.resourceKeys
    let contents = fm.enumerator(at: folder, includingPropertiesForKeys: resourceKeys, options: listOpts)!
    
    var files = ContentPointerURLMapping(contents: [:])
    
    while let fileURL = autoreleasepool(invoking: { contents.nextObject() }) as? URL {
      guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
            let fileType = resourceValues.contentType
      else {
        logger.emit(.warning, "Error getting the file \(fileURL.lastPathComponent)")
        continue
      }
      
      if types.allows(filetype: fileType) == false { continue }
      
      guard let contentId = try? metadata.retrieveXID(for: fileURL) else { continue }
      
      let contentPointer = ContentPointer(id: contentId, filePath: fileURL.filepath)

      files.insert(contentPointer, at: fileURL)

    }
    
    cache.add(forParams: cachekey, items: files)
    
    return files
  }
  
  
  /**
   * Returns the directory contents as a collection of `ContentPointer` objects,
   * generating contentId extended attribute values for any items that do not have one.
   *
   * - Parameters:
   *   - path: The directory to index
   *   - mode: A `ListMode` mode, either immediate or recursive
   *   - types: A `AllowedFileTypes` set of types
   */
  func indexContents(at path: FilePath, mode: ListMode, types: ContentTypeGroup) -> [ContentPointer] {
    
    let listOpts = mode.forURL(path.fileURL)
    
    guard let contents = fm.enumerator(
      at: path.fileURL, includingPropertiesForKeys: URLResourceKeySet.basic.resourceKeys, options: listOpts)
    else {
      return []
    }
    
    var files: [ContentPointer] = []
    
    while let fileURL = autoreleasepool(invoking: { contents.nextObject() }) as? URL {
      
      guard let contentType: UTType = fileURL.resourceValue(forKey: .contentTypeKey) else {
        logger.emit(.warning, "Error getting UTType for \(fileURL.lastPathComponent)")
        continue
      }
      
      guard types.allows(filetype: contentType) else { continue }
      
      do {
        if let contentId = try metadata.retrieveXID(for: fileURL) {
          files.append(ContentPointer(id: contentId, filePath: fileURL.filepath))
          continue
        }
      } catch {
        logger.emit(.error, ErrorMsg("Error retrieving XID for \(fileURL.filepath)", error))
      }
      
      do {
        let contentId = try metadata.assignNewXID(to: fileURL)
        files.append(ContentPointer(id: contentId, filePath: fileURL.filepath))
      } catch {
        logger.emit(.error, ErrorMsg("Error assigning new XID to \(fileURL.filepath)", error))
      }
    }
    
    return files
  }
  
  
    // MARK: - .listVolumes()
  
  /**
   * Lists all mounted volumes on the system.
   *
   * This function retrieves all mounted volume URLs, including their resource values,
   */
  func listVolumes() -> Set<URL> {
    let resourceKeys = URLResourceKeySet.volume.resourceKeys
    
    guard let volumes = fm.mountedVolumeURLs(
      includingResourceValuesForKeys: resourceKeys,
      options: .skipHiddenVolumes
    ) else {
      return []
    }
    
    return Set(volumes)
  }
  
    // MARK: - .getVolumesInfo()
  
  
  /**
   * Retrieves information about all mounted volumes.
   */
  func getVolumesInfo() -> [VolumeInfo] {
    listVolumes().compactMap { $0.volumeInfo }
  }
  
    // MARK: - .rename(src:dest:)
  
  
  /**
   * Renames a file or directory from `src` to `dest`.
   *
   * - Parameters:
   *   - src: The source file path to rename.
   *   - dest: The destination file path to rename to.
   *
   * This function checks if the source exists, if the destination does not exist,
   * and if the destination directory is valid before performing the rename operation.
   *
   * Throws an error if any of the conditions are not met.
   */
  func rename(_ src: URL, to dest: URL) throws(LocalFileServiceError) {
    try rename(src.filepath, to: dest.filepath)
  }
  
  
  /**
   * Renames a file or directory from `src` to `dest`.
   *
   * - Parameters:
   *   - src: The source file path to rename.
   *   - dest: The destination file path to rename to.
   *
   * This function checks if the source exists, if the destination does not exist,
   * and if the destination directory is valid before performing the rename operation.
   *
   * Throws an error if any of the conditions are not met.
   */
  func rename(_ src: FilePath, to dest: FilePath) throws(LocalFileServiceError) {
    if src == dest {
      logger.emit(.warning, "No change in file name")
      return
    }
    
    guard src.exists() else {
      throw .sourceFileNoExist(src)
    }
    
    guard !dest.exists() else {
      throw .targetFileAlreadyExists(dest)
    }
    
    guard dest.directory.exists() else {
      throw .targetDirNoExist(dest.directory)
    }
    
    guard dest.directory.isBrowsable() else {
      throw .targetDirInvalid(dest.directory, "Volume not found")
    }
    
    do {
      try src.move(to: dest)
    } catch CocoaError.fileWriteFileExists {
      throw .targetFileAlreadyExists(dest)
    } catch {
      throw .renameError(error)
    }
    
    logger.emit(.success, ["Renamed file:", src.string, dest.string].joined(separator: "\n"))
  }
  
    // MARK: - .exists(at:)
  
  
  /**
   * Checks if a file or directory exists at the specified URL.
   *
   * - Parameter url: The URL to check for existence.
   *
   * - Returns: `true` if the file or directory exists, `false` otherwise.
   */
  func exists(at url: URL) -> Bool {
    return fm.fileExists(atPath: url.filepath.string)
  }
  
  
  /**
   * Checks if a file or directory exists at the specified path.
   *
   * - Parameter path: The file path to check for existence.
   *
   * - Returns: `true` if the file or directory exists, `false` otherwise.
   */
  func exists(at path: FilePath) -> Bool {
    return fm.fileExists(atPath: path.string)
  }
  
    // MARK: - .touch(_:)
  
  
  /**
   * Creates a file at the specified URL if it does not already exist.
   *
   * - Parameter url: The URL of the file to create.
   *
   * - Returns: `true` if the file was created, `false` if it already exists.
   *
   * Throws an error if the file cannot be created.
   */
  @discardableResult
  func touch(_ url: URL) throws -> Bool {
    try touch(url.filepath)
  }
  
  /**
   * Creates a file at the specified file path if it does not already exist.
   *
   * - Parameter filepath: The file path of the file to create.
   *
   * - Returns: `true` if the file was created, `false` if it already exists.
   *
   * Throws an error if the file cannot be created.
   */
  @discardableResult
  func touch(_ filepath: FilePath) throws -> Bool {
    if filepath.exists() {
      return true
    }
    
    if filepath.isDirectory {
      try mkdir(at: filepath)
      return true
    }
    
    try mkdir(at: filepath.directory)
    return filepath.createFile()
  }
  
    // MARK: - .mkdir(at:)
  
  
  /**
   * Creates a directory at the specified URL.
   *
   * - Parameter url: The URL of the directory to create.
   *
   * Throws an error if the directory cannot be created.
   */
  func mkdir(at filepath: FilePath) throws {
    try fm.createDirectory(atPath: filepath.string, withIntermediateDirectories: true)
  }
  
  
  /**
   * Moves a file to the trash.
   *
   * - Parameter filepath: The file path of the file to move to the trash.
   *
   * - Returns: `true` if the file was successfully moved to the trash, `false` otherwise.
   *
   * Throws an error if the file cannot be moved to the trash.
   */
  func moveToTrash(_ filepath: FilePath) throws -> Bool {
    try fm.trashItem(at: filepath.fileURL, resultingItemURL: nil)
    
    logger.emit(.success, "Moved \(filepath.string) to trash")
    
    return self.exists(at: filepath) == false
  }
  
  
  /**
   * Creates a zip archive of the specified source file at the specified archive path.
   *
   * - Parameters:
   *   - source: The file path of the source file to archive.
   *   - archivePath: The file path where the zip archive should be created.
   *
   * Throws an error if the zip archive creation fails.
   */
  func createZipArchive(of source: FilePath, at archivePath: FilePath) throws {
    logger.emit(.info, "Creating zip archive at \(archivePath.string)")
    
    let created = SSZipArchive.createZipFile(
      atPath: archivePath.string,
      withFilesAtPaths: [source.string],
    )
    
    guard created else {
      throw LocalFileServiceError.zipCreationFailed(archivePath)
    }
  }
}



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
