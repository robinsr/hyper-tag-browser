// created on 4/2/25 by robinsr

import Defaults
import Factory
import SwiftUI


struct ThumbnailCacheViewModifier: ViewModifier {
  
  private let logger = EnvContainer.shared.logger("CachedThumbnailProviderView")
  
  @Environment(\.dbContentItemsVisible) var items: [ContentItem]
  
  @Injected(\Container.quicklookService) private var quicklook
  @Injected(\Container.thumbnailStore) private var thumbnailStore

//  var thumbnailSize: CGSize {
//    Defaults[.thumbnailQuality].size
//  }
  
//  func setThumbnail(_ data: Data, for id: ContentId) {
//    do {
//      try thumbnailStore.setData(data, forContent: id)
//    } catch {
//      logger.emit(.error, ErrorMsg("Failed to set thumbnail for \(id)", error))
//    }
//  }
  
//  func requestThumbnail(for item: ContentItem) async -> Data? {
//    await quicklook.bestRepresentation(for: item.url, size: thumbnailSize).imageData
//  }
  
//  func onContentItemsChange() {
//    items.filter(\.hasThumbnail).forEach { item in
//      if let data = item.thumbnailData {
//        setThumbnail(data, for: item.id)
//      }
//    }
//
//    items.filter(thumbnailStore.cacheMiss).forEach { item in
//      DispatchQueue.global(qos: .userInitiated).async {
//        Task {
//          guard let imageData = await requestThumbnail(for: item) else { return }
//          
//          DispatchQueue.main.async {
//            setThumbnail(imageData, for: item.id)
//          }
//        }
//      }
//    }
//  }
  
  func body(content: Content) -> some View {
    content
      .environment(\.thumbnailStore, thumbnailStore)
//      .onChange(of: items, initial: true) {
//        onContentItemsChange()
//      }
  }
}


extension View {
  func withThumbnailCache() -> some View {
    modifier(ThumbnailCacheViewModifier())
  }
}

extension EnvironmentValues {
  @Entry var thumbnailStore: ThumbnailStore = Container.shared.thumbnailStore()
}
