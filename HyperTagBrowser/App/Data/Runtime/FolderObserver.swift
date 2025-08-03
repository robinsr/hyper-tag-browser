// created on 4/2/25 by robinsr

import Factory
import Foundation
import AppKit
import UniformTypeIdentifiers
import System


/**
 * Conforming to `FolderObserverDelegate` allows you to receive
 * notifications when the contents of a folder change.
 */
protocol FolderObserverDelegate {
  var ignorePaths: Set<FilePath> { get set }
  func onUnknownChange(at: URL)
  func onFamiliarChange(item: ContentItem, url: URL)
}


class FolderObserver: NSObject, NSFilePresenter {
  
  @Injected(\IndexerContainer.indexService) var indexer
  @Injected(\Container.metadataService) var metadata
  
  lazy var presentedItemOperationQueue = OperationQueue.main
  
  var presentedItemURL: URL?
  
  private let delegate: FolderObserverDelegate
  
  init(withDelegate delegate: FolderObserverDelegate, url: URL) {
    self.delegate = delegate
    self.presentedItemURL = url

    super.init()

    NSFileCoordinator.addFilePresenter(self)
  }
  
  deinit {
    NSFileCoordinator.removeFilePresenter(self)
  }
  
  private let ignoreNames: [String] = [
    ".DS_Store", // macOS system file
    ".localized", // macOS localization file
    "Thumbs.db", // Windows thumbnail cache
    "__MACOSX" // macOS archive metadata folder
  ]
  
  private lazy var includeTypes: Set<UTType> = {
    ContentTypeGroup.content.filetypes
  }()
  
  private let homePath = URL.homeDirectory.filepath
  
    // Tells the delegate that the contents or attributes of the specified item changed.
  func presentedSubitemDidChange(at url: URL) {
    let urlpath = url.filepath
    let urlext = url.fileExtension
    
    let ignoreDirs = self.delegate.ignorePaths
    
    // This method will be called a lot, so attempting to return as early as possible with the least amount of work.
    
    // First check the content-type. Dont use URL.contentType as it invokes URLResourceKey which will fail
    // for non-existent files or files that can't be accessed. Instead derive the type from the file extension.
    // Any files where getting the UTType fails are irrelevant for the app anyway, so are ignored
    guard let contentType = UTType(filenameExtension: urlext) else { return }
    
    // Check if the contentType is of a type we care about
    guard includeTypes.contains(contentType) else { return }
    
    // Check if the changed file is a descendant of any of the ignored directories
    guard !ignoreDirs.contains(startOf: urlpath) else { return }
    
    
    // Check if its disallowed by filename (e.g. system files)
    if ignoreNames.contains(url.filename) { return }
    
    
    guard let contentId = try? metadata.retrieveXID(for: url) else {
      // Ignore files that are not recognized as content
      self.delegate.onUnknownChange(at: url)
      return
    }
    
    do {
      guard let indx = try indexer.getIndexInfo(withId: contentId) else {
        print("No index found for contentId \(contentId)")
        return
      }
      
      self.delegate.onFamiliarChange(item: indx, url: url) 
    } catch {
      print("Error reading index for contentId \(contentId): \(error)")
    }
  }
}


