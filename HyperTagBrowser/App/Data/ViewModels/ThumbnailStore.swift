// created on 2/10/25 by robinsr

import Cache
import CoreImage
import Defaults
import Factory
import Foundation
import System
import UniformTypeIdentifiers


@MainActor
@Observable
final class ThumbnailStore {
  private let logger = EnvContainer.shared.logger("ThumbnailStore")

  private let ql = Container.shared.quicklookService()
  private let store = ThumbnailContainer.shared.cache()

  private var thumbnailSize: CGSize {
    Defaults[.thumbnailQuality].size
  }

  @ObservationIgnored
  private var token: ObservationToken?
  
  @ObservationIgnored
  private let fetchQueue = ThumbnailFetchQueue()

  @ObservationIgnored
  private var fetchQueueCancellable: AnyCancellable?


  init() {

    fetchQueueCancellable = self.fetchQueue.$items
      .compactMap(\.first)
      .removeDuplicates()
      .sink { item in
        self.logger.emit(.debug.off, "ThumbnailStore: fetchQueue has item: \(item.id)")

        // handle new item
        Task.detached(priority: .userInitiated) { [self] in
          // Could return early if already cached, except for thumbnail update
          // guard self.cacheMiss(item.id) else { return }

          let data = await self.thumbnailData(for: item)

          Task {
            await MainActor.run {
              try! self.setData(data, forContent: item.id)
              self.fetchQueue.remove(item)
            }
          }
        }
      }

    token = store.addStorageObserver(self) { observer, storage, change in
      switch change {
        case .add(let key):
          self.logger.emit(.debug.off, "Thumbnail added to store: \(key.shortId.quoted)")
          self.keys.insert(key)
        case .remove(let key):
          self.logger.emit(.debug.off, "Thumbnail removed from store: \(key.shortId.quoted)")
          self.keys.remove(key)
        case .removeAll:
          self.logger.emit(.debug.off, "Thumbnail store cleared")
          self.keys.removeAll()
        default:
          break
      }
    }
  }
  

  private func thumbnailData(for task: ThumbnailFetchTask) async -> Data {
    await Task.detached(priority: .userInitiated) {
      switch task.source {
      case .quicklook:
        return await self.ql.bestRepresentation(for: task.contentURL, size: self.thumbnailSize).imageData
      case .cgImage:
        return ImageDisplay.small(.squared).jpegData(url: task.contentURL) ?? Data()
      }
    }.value
  }

  private func setData(_ data: Data, forContent id: ContentId) throws {
    try store.setObject(data, forKey: id)
  }
  
  
  //
  // MARK: - Public API
  //
  
  /// Set of ContentIds currently in the store. Public, use for observation.
  public var keys: Set<ContentId> = []

  public func clearThumbnail(forContent id: ContentId) throws {
    guard cacheHit(id) else {
      logger.emit(.debug.off, "ThumbnailStore: clearThumbnail: no thumbnail for \(id.shortId.quoted)")
      return
    }
    
    try store.removeObject(forKey: id)
  }

  public func clear() throws {
    try store.removeAll()
  }
  
  public func hasThumbnail(for content: ContentItem) -> Bool {
    return cacheHit(content.id)
  }

  public func thumbnailImage(for content: ContentItem) -> CGImage? {
    if let imageData = try? store.object(forKey: content.id) {
      return ImageDisplay.full.cgImage(from: imageData)
    }

    fetchQueue.addItem(content)

    return nil
  }

  public func thumbnailImageData(for content: ContentItem) -> Data? {
    if let imageData = try? store.object(forKey: content.id) {
      return imageData
    }

    fetchQueue.addItem(content)

    return nil
  }

  private func cacheHit(_ id: ContentId) -> Bool {
    guard let exists = try? store.existsObject(forKey: id) else { return false }

    return exists
  }

  private func cacheMiss(_ id: ContentId) -> Bool {
    !cacheHit(id)
  }
}

extension ThumbnailStore {

  /**
   * Defines a task for fetching a thumbnail image.
   */
  struct ThumbnailFetchTask: Hashable, Sendable, Identifiable, Equatable {

    let id: ContentId
    let contentURL: URL
    let contentType: UTType

    init(_ content: ContentItem) {
      self.id = content.id
      self.contentURL = content.url
      self.contentType = content.contentType
    }
    
    var source: ThumbnailSource {
      let flags = PreferencesContainer.shared.prefs().forKey(.devFlags)
      
      switch contentType {
      case .image:
        return flags.contains(.enable_cgImageThumbnail) ? .cgImage : .quicklook
      default:
        return .quicklook
      }
    }
    
    enum ThumbnailSource {
      case quicklook, cgImage
    }
    
    struct Result: Hashable, Sendable {
      let task: ThumbnailFetchTask
      let data: Data

      init(task: ThumbnailFetchTask, data: Data) {
        self.task = task
        self.data = data
      }
    }
    
    static func == (lhs: ThumbnailFetchTask, rhs: ThumbnailFetchTask) -> Bool {
      lhs.id == rhs.id
    }
  }

  /**
   * A queue for managing thumbnail fetch tasks.
   */
  class ThumbnailFetchQueue {
    @Published private(set) var items: Set<ThumbnailFetchTask>

    init() {
      items = []
    }

    func addItem(_ content: ContentItem) {
      let item = ThumbnailFetchTask(content)
      if items.contains(item) == false {
        items.insert(item)
      }
    }

    func remove(_ item: ThumbnailFetchTask) {
      items.remove(item)
    }
  }
}
