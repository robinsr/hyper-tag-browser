// created on 4/2/25 by robinsr

import Defaults
import Factory
import SwiftUI


struct ThumbnailCacheViewModifier: ViewModifier {
  
  private let logger = EnvContainer.shared.logger("CachedThumbnailProviderView")
  
  @Environment(\.dbContentItemsVisible) var items: [ContentItem]
  
  @Injected(\Container.quicklookService) private var quicklook
  @Injected(\ThumbnailContainer.store) private var thumbnailStore

  
  func body(content: Content) -> some View {
    content
      .environment(\.thumbnailStore, thumbnailStore)
  }
}


extension View {
  func withThumbnailCache() -> some View {
    modifier(ThumbnailCacheViewModifier())
  }
}

extension EnvironmentValues {
  @Entry var thumbnailStore: ThumbnailStore = ThumbnailContainer.shared.store()
}
