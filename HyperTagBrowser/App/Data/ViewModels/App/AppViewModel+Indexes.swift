// created on 11/24/25 by robinsr

import Defaults
import Factory
import Foundation

actor IndexingQueue {
  private var last: Task<Void, Never>?

  func enqueue(_ op: @escaping @Sendable () async -> Void) {
    let previous = last
    last = Task {
      _ = await previous?.value
      await op()
    }
  }
}

fileprivate let queue = IndexingQueue()

extension AppViewModel {
  
    // MARK: - Managing Index Actions IMPL
  
  func doIndexDirectory(_ url: URL) async {

    // Temporarily stop folder observation
    Task {
      await folderObserver?.stop()
    }
    
    Task {
      await queue.enqueue { [indexer, messages, url] in
        let path = url.filepath
        await messages.send("Indexing directory: \(path.string)")
        
        do {
          let result = try await indexer.indexDirectory(at: path)

          if result.hasDuplicates {
            await messages.send(reject: "\("Duplicate item", qty: result.duplicates.count) found in \(path.baseName)")
          }
          
          await messages.send(ok: "\(result.description) indexed")
        } catch {
          await messages.send(ErrorMsg("Error while indexing folder \(path.baseName)", error))
        }
      }
      
      await queue.enqueue {
        await self.doReloadQuery()
      }
      
      await queue.enqueue { [currentPath] in
        await self._startFolderObservation(at: currentPath)
      }
    }
  }
  
  func doRemoveIndex(of pointers: Pointers) {
    Task {
      do {
        let count = try await indexer.deleteIndexes(withIds: pointers.ids)
        
        messages.send(ok: "Removed \("items", qty: count) from index")
      } catch {
        messages.send(ErrorMsg("Could not remove items from index", error))
      }
    }
  }
  
  func doBackupDatabase() {
    let timestamp = DateFormatter.filename.string(from: .now)
    let archiveName = "userdb-\(currentProfile.id)-\(timestamp).zip"

    let dbFilePath = currentProfile.dbFile.filepath
    let archivePath = dbFilePath.directory.appending(archiveName)

    Task.detached(priority: .userInitiated) { [self] in
      do {
        try LocalFileService().createZipArchive(of: dbFilePath, at: archivePath)
        await messages.send(ok: "Database backup created at \(archivePath)")
      } catch {
        await messages.send(ErrorMsg("Error creating backup", error))
      }
    }

    messages.send(ok: "Creating new database backup...")
  }
  
  
  @available(*, deprecated, message: "Unused as of 2025-11-24")
  func doUpdateIndexes(using patches: [IndexRecord.Update]) {
    Task {
      do {
        for patch in patches {
          let _ = try await indexer.updateIndexes(with: patch)
        }
        
        messages.send(ok: "Updated \("Item", qty: patches.count)")
      } catch {
        messages.send(ErrorMsg("Error updating indexes", error))
      }
    }
  }
}
