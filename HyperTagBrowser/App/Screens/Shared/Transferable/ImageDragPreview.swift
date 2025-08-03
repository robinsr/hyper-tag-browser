// created on 4/2/25 by robinsr

import Factory
import SwiftUI

struct ImageDragPreview: View {
  @Injected(\Container.thumbnailStore) var thumbnailStore
  @Environment(\.photoGridState) var gridState
  
  let contentItem: ContentItem
  
  var itemSize: CGFloat {
    // Scale image size to accomodate for rotation clipping
    gridState.itemWidth * 0.7
  }
  
  var body: some View {
    if let thumbnail = thumbnailStore.thumbnailImage(for: contentItem) {
      Image(decorative: thumbnail, scale: 1.0, orientation: .up)
        .resizable()
        .scaledToFit()
        .frame(width: itemSize, height: itemSize)
    }
  }
}
