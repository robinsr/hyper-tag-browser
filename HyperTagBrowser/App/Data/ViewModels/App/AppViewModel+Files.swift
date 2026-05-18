// created on 11/24/25 by robinsr

import AppKit
import Foundation
import System

extension AppViewModel {
  
  // MARK: - File Actions IMPL
  
  func doRevealFinderItem(at url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }
  
    // MARK: - File Observation
  
  func _startFolderObservation(at filepath: FilePath) {
    do {
      let observer = try FolderObserver(at: filepath)
      
      Task {
        for await event in await observer.stream() {
          self._handleFolderEvent(event)
        }
      }
      
    } catch {
      logger.emit(.error, ErrorMsg("Failed to create FolderObserver", error))
    }
  }
  
  private func _handleFolderEvent(_ evt: FolderObserverEvent) {
    switch evt {
    case .known(let index, let filepath):
      Task { await _handleMovedIndex(index, filepath) }
    case .unknown(let filepath):
      Task { await _handleNewFile(filepath) }
    }
  }
  
  private func _handleMovedIndex(_ index: ContentItem, _ filepath: FilePath) async {
    let itemDir = filepath.directory
      // Ignore automatic content updates when not browsing a folder
    guard currentPage == .folder else { return }
      // Ignore automatic content updates when content item appears in another folder (item moved to subfolder)
    guard currentPath == itemDir else { return }
    
    logger.emit(.info, "Content \(index.id) moved to \(filepath.directory.string)")
    
    Task {
      do {
        let record = try await indexer.createIndex(for: filepath)
        logger.emit(.success, "Updated index for \(record.id)")
        await reloadDebouncer?.debounce()
      } catch {
        logger.emit(.error, ErrorMsg("Failed to upate index for \(filepath.string.quoted)", error))
      }
    }
  }
  
  @MainActor
  private func _handleNewFile(_ filepath: FilePath) async {
    let itemDir = filepath.directory
    let itenName = filepath.baseName
      // Ignore automatic content updates when not browsing a folder
    guard currentPage == .folder else { return }
      // Ignore automatic content updates when content item appears in another folder (item moved to subfolder)
    guard currentPath == itemDir else { return }
    
    logger.emit(.info, "New file \(itenName.quoted) added to folder \(itemDir.string)")
    
    Task {
      do {
        let record = try await indexer.createIndex(for: filepath)
        await reloadDebouncer?.debounce()
        logger.emit(.success, "Created index for \(record.id)")
      } catch {
        logger.emit(.error, ErrorMsg("Failed to create index for \(filepath.string.quoted)", error))
      }
    }
  }
}
