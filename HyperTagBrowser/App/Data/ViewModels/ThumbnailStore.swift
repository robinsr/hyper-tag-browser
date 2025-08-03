// created on 2/10/25 by robinsr

import Cache
import CoreImage
import Defaults
import Factory
import Foundation
import System
import UniformTypeIdentifiers


@Observable
final class ThumbnailStore {
  private let logger = EnvContainer.shared.logger("ThumbnailStore")

  private let quicklookService = Container.shared.quicklookService()

  static let diskCacheDirectory: FilePath = {
    EnvContainer.shared.stagedPath().appending("thumbstore").filepath
  }()

  static let diskCacheExpiry: Expiry = .days(15)

  private let diskCacheConfiguration: DiskConfig = {
    DiskConfig(name: diskCacheDirectory.string, expiry: diskCacheExpiry)
  }()

  private let memoryCacheConfiguration: MemoryConfig = {
    MemoryConfig(expiry: .minutes(30), countLimit: 10, totalCostLimit: 10)
  }()

  var thumbnailSize: CGSize {
    Defaults[.thumbnailQuality].size
  }

  @ObservationIgnored
  private let store: Storage<ContentId, Data>

  @ObservationIgnored
  private var token: ObservationToken?
  
  @ObservationIgnored
  private let fetchQueue = ThumbnailFetchQueue()

  @ObservationIgnored
  private var fetchQueueCancellable: AnyCancellable?


  init() {

    store = try! Storage<ContentId, Data>(
      diskConfig: diskCacheConfiguration,
      memoryConfig: memoryCacheConfiguration,
      fileManager: FileManager.default,
      transformer: TransformerFactory.forData()
    )
  

    fetchQueueCancellable = self.fetchQueue.$items
      .compactMap(\.first)
      .removeDuplicates()
      .sink { item in
        self.logger.emit(.debug.off, "ThumbnailStore: fetchQueue has item: \(item.id)")

        // handle new item
        Task.detached(priority: .userInitiated) { [self] in
          // Could return early if already cached, except for thumbnail update
          // guard self.cacheMiss(item.id) else { return }

          let data = await self.requestThumbnail(task: item)

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

  /// Toggle to disable thumbnail caching for testing.
  private let useQuicklookForImgThumbnails: Bool = true

  private enum ThumbnailSource {
    case quicklook
    case cgImage
  }

  private func thumbnailingSource(for uttype: UTType) -> ThumbnailSource {
    if uttype.conforms(to: .folder) {
      return .quicklook
    }

    if uttype.conforms(to: .image) {
      return useQuicklookForImgThumbnails ? .quicklook : .cgImage
    }

    return .quicklook
  }

  private func requestThumbnail(task: ThumbnailFetchTask) async -> Data {
    let thumbnailSource = thumbnailingSource(for: task.contentType)

    switch thumbnailSource {
      case .quicklook:
        return
          await quicklookService
          .bestRepresentation(for: task.contentURL, size: thumbnailSize)
          .imageData
      case .cgImage:
        return
      await Task.detached(priority: .userInitiated) {
            self.getContentImage(url: task.contentURL)
          }.value
    }
  }

  private func getContentImage(url contentURL: URL) -> Data {
    return ImageDisplay.small(.squared).jpegData(url: contentURL) ?? Data()
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

  private func cacheHit(_ item: AnyIdentifiableContentItem) -> Bool {
    return cacheHit(item.id)
  }

  private func cacheMiss(_ id: ContentId) -> Bool {
    !cacheHit(id)
  }

  private func cacheMiss(_ item: AnyIdentifiableContentItem) -> Bool {
    !cacheHit(item.id)
  }
}

extension ThumbnailStore {

  /**
   * Defines a task for fetching a thumbnail image.
   */
  struct ThumbnailFetchTask: Hashable, Sendable {
    let id: ContentId
    let contentURL: URL
    let contentType: UTType

    init(_ content: ContentItem) {
      self.id = content.id
      self.contentURL = content.url
      self.contentType = content.contentType
    }
    
    struct Complete: Hashable, Sendable {
      let task: ThumbnailFetchTask
      let data: Data

      init(task: ThumbnailFetchTask, data: Data) {
        self.task = task
        self.data = data
      }
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

extension Expiry {
  
  static func minutes(_ minutes: Int) -> Expiry {
    return .seconds(TimeInterval(minutes * 60))
  }
  
  static func hours(_ hours: Int) -> Expiry {
    return .seconds(TimeInterval(hours * 60 * 60))
  }
  
  static func days(_ days: Int) -> Expiry {
    return .seconds(TimeInterval(days * 24 * 60 * 60))
  }
}
