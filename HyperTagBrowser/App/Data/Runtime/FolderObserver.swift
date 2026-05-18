// created on 4/2/25 by robinsr

import AppKit
import Factory
@preconcurrency import FileMonitor
import Foundation
import System
import UniformTypeIdentifiers


enum FolderObserverEvent {
  case known(ContentItem, FilePath)
  case unknown(FilePath)
}

actor FolderObserver {

  typealias Event = FolderObserverEvent

  private let indexer = IndexerContainer.shared.indexService()
  private let metadata = Container.shared.metadataService()
  private let logger = EnvContainer.shared.logger("FolderObserverResponder")

  private let filepath: FilePath
  private var monitor: FileMonitor?
  private var cont: AsyncStream<Event>.Continuation?
  private var task: Task<(), Never>?

  init(at path: FilePath) throws {
    filepath = path
    //presenter = Presenter(url: path.fileURL)
    monitor = try FileMonitor(directory: path.fileURL)
    
    guard let stream = monitor?.stream else {
      logger.emit(.error, "No stream from file monitor")
      return
    }
    
    Task {
      for await event in stream {
        switch event {
        case .added(let file):
          logger.emit(.info, "New file \(file.path)")
          await self.handle(file)
        case .changed(let changedURL):
          logger.emit(.info, "Ignored file change event: \(changedURL.path)")
        case .deleted(let deletedFile):
          logger.emit(.info, "Ignored file deleted event: \(deletedFile.path)")
        }
      }
    }
    
    Task {
      try await monitor?.start()
    }

    logger.emit(.info, "New FolderObserverResponder at url \(filepath.string)")
  }
  
  deinit {
    monitor?.stop()
    monitor = nil
  }


  func stream() -> AsyncStream<Event> {
    AsyncStream(Event.self) { continuation in
      self.cont = continuation
      continuation.onTermination = { [weak self] _ in
        Task {
          await self?.stop()
        }
      }
    }
  }

  func send(_ event: Event) { cont?.yield(event) }

  func stop() {
    cont?.finish()
    cont = nil
  }

  private let ignoredDirectories: Set<FilePath> = [
    FilePath("~/Library").expandingTilde()
  ]

  private let ignoreNames: [String] = [
    ".DS_Store",          // macOS system file
    ".localized",          // macOS localization file
    "Thumbs.db",          // Windows thumbnail cache
    "__MACOSX",          // macOS archive metadata folder
  ]


  /**
   * Tells the delegate that the contents or attributes of the specified item changed. This method
   * is invoked a lot, so attempting to return as early as possible with the least amount of work.
   */
  func handle(_ url: URL) {
    // Ignore file deletion and file renames
    guard url.filepath.exists else { return }

    // First check the content-type. Dont use URL.contentType as it invokes URLResourceKey which will fail
    // for non-existent files or files that can't be accessed. Instead derive the type from the file extension.
    // Any files where getting the UTType fails are irrelevant for the app anyway, so are ignored
    guard let contentType = UTType(filenameExtension: url.fileExtension) else { return }

    // Check if the contentType is of a type we care about
    guard ContentTypeGroup.content.filetypes.contains(contentType) else { return }

    // Check if the changed file is a descendant of any of the ignored directories
    guard !ignoredDirectories.contains(startOf: url.filepath) else { return }

    // Check if its disallowed by filename (e.g. system files)
    if ignoreNames.contains(url.filename) { return }

    logger.emit(.debug.off, "Subitem appeared: \(url.filepath.string)")

    Task {
      if let contentId = try? metadata.retrieveXID(for: url),
         let record = try? await indexer.getContentItem(withId: contentId)
      {
        self.send(.known(record, url.filepath))
      } else {
        self.send(.unknown(url.filepath))
      }
    }
  }
}
