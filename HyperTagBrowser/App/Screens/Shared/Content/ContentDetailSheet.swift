// created on 1/16/25 by robinsr

import Factory
import SwiftUI

struct ContentDetailSheet: View, SheetPresentable {
  static private let widthRange: ClosedRange<CGFloat> = 500...800
  
  @Injected(\ThumbnailContainer.store) var tStore
  
  static let presentation: SheetPresentation = .full(controls: .close)

  var content: ContentItem
  
  var thumbnailImage: NSImage? {
    tStore.thumbnailImage(for: content)?.asNSImage
  }

  var body: some View {
    NavigationStack {
      VStack {
        VStack {
          HStack(alignment: .top, spacing: 0) {
            ContentThumbnailInfo
            ContentAttributeTable
          }
          ContentTagsBlock
        }
        .modalContentMain(alignment: .top, padding: .zero)
      }
      .modalContentBody()
      .navigationTitle("Details for \(content.name, truncate: 50)")
    }
  }
  
  var ContentThumbnailInfo: some View {
    VStack(alignment: .center) {
      Group {
        if let img = thumbnailImage {
          ImageBox("Cached Thumbnail", nsImage: img, resizable: true)
        } else {
          Text("No thumbnail available")
        }
      }
      .padding(8)
      .frame(maxWidth: .infinity)
      .foregroundColor(.secondary)
    }
    .frame(maxWidth: 200, maxHeight: 200)
    .modalContentSection("Thumbnail", spacing: 0)
  }
  
  var ContentAttributeTable: some View {
    VStack {
      ContentAttributes(contentItem: content)
    }
    .modalContentSection("Attributes", spacing: 0)
  }
  
  var ContentTagsBlock: some View {
    VStack {
      CurrentTagsView(
        contentItem: .constant(content),
        domains: .constant([.attribution, .descriptive, .queue])
      )
    }
    .modalContentSection("Current Tags", spacing: 0)
  }
}


#Preview("ContentDetailSheet", traits: .defaultViewModel) {
  @Previewable @Environment(AppViewModel.self) var appVM
  
  VStack {
    if let content = appVM.contentItems.first {
      ContentDetailSheet(content: content)
    }
  }
  .scenePadding()
  .frame(width: 500, height: 400)
  .background(.background)
  .colorScheme(.dark)
}
