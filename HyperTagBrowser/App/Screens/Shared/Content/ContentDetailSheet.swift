// created on 1/16/25 by robinsr

import Factory
import SwiftUI

struct ContentDetailSheet: View, SheetPresentable {
  static private let widthRange: ClosedRange<CGFloat> = 500...800
  
  @Injected(\Container.thumbnailStore) var tStore
  
  static let presentation: SheetPresentation = .full(controls: .close)

  var content: ContentItem
  
  var thumbnailImage: NSImage? {
    tStore.thumbnailImage(for: content)?.asNSImage
  }

  var body: some View {
    VStack {
      VStack {
        
        HStack(alignment: .top, spacing: 0) {
          VStack(alignment: .center) {
            ThumbnailDetail
          }
          .frame(maxWidth: 200, maxHeight: 200)
          .modalContentSection("Thumbnail", spacing: 0)
          
          VStack {
            ContentAttributes(contentItem: content)
          }
          .modalContentSection("Attributes", spacing: 0)
        }
        
        
        VStack {
          CurrentTagsView(
            contentItem: .constant(content),
            domains: .constant([.attribution, .descriptive, .queue])
          )
        }
        .modalContentSection("Current Tags", spacing: 0)
      }
      .modalContentMain(alignment: .top, padding: .zero)
      
    }
    .modalContentBody()
  }
  
  var ThumbnailDetail: some View {
    VStack(alignment: .center, spacing: 4) {
      if let img = thumbnailImage {
        ImageBox("Cached Thumbnail", nsImage: img, resizable: true)
          //.frame(maxWidth: 200, maxHeight: 200)
          //.fillFrame(.horizontal)
      } else {
        Text("No thumbnail available")
          .foregroundColor(.secondary)
      }
    }
    .padding(8)
    .frame(maxWidth: .infinity)
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
