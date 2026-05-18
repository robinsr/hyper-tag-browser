// created on 4/2/25 by robinsr

import Factory
import SwiftUI

struct ContentDragPreview: View {
  
  @Injected(\ThumbnailContainer.store) var thumbnailStore
  @Environment(\.photoGridState) var gridState
  
  let items: [ContentItem]
  let itemCount: Int = 22
  let rotationMax: Angle = .degrees(78.0)
  
  var body: some View {
    FannedItemsView(
      data: items,
      maxItems: itemCount,
      spread: .incremental(maxAngle: rotationMax, atCount: 10, approach: .linear),
      direction: .anticlockwise,
      anchor: .center,
      size: .init(width: gridState.itemWidth, height: gridState.itemWidth)
    ) { item in
      if let _ = thumbnailStore.thumbnailImageData(for: item) {
        ImageDragPreview(contentItem: item)
      }
    }
    .frame(width: gridState.itemWidth, height: gridState.itemWidth)
  }
}
