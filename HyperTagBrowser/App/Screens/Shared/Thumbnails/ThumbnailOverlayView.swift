// created on 2/19/25 by robinsr

import SwiftUI
import UniformTypeIdentifiers


struct ThumbnailOverlayView: View {
  var icon: SymbolIcon = .info
  var iconFont: Font = .system(size: 12)
  var label: String = ""
  var alignment: Alignment = .topLeading

  var body: some View {
    HStack(spacing: 2) {
      Image(icon)
        .font(iconFont)
      
      Text(label)
        .lineLimit(1)
        .font(iconFont)
    }
    .fillFrame([.horizontal, .vertical], alignment: alignment)
    .opacity(0.85)
    .colorScheme(.dark)
  }
}



#Preview("ThumbnailOverlayView", traits:
  .devFlags(.enable_obscureContent),
  .defaultViewModel,
  .fixedLayout(width: 600, height: 400),
  .testBordersOn
) {
  
  @Previewable @State var images: [NSImage] = TestData.testImages(
    limit: 9,
    resizedTo: .sized(.init(widthHeight: 50), .squared),
    shuffled: true)
  
  @Previewable @State var cols: [GridItem] = Array(repeating: GridItem(.fixed(200)), count: 3)
  
  @Previewable @State var gridState = PhotoGridState(gridWidth: 600, itemWidth: 200)
  
  LazyVGrid(columns: cols, spacing: 8) {
    ForEach(images, id: \.self) { nsImage in
      Image(nsImage: nsImage)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .overlay {
          ThumbnailOverlayView(icon: .camera, alignment: .bottomLeading)
          ThumbnailOverlayView(icon: .trash, alignment: .bottomTrailing)
          ThumbnailOverlayView(icon: .eyeslash, alignment: .topLeading)
          ThumbnailOverlayView(icon: .gear, alignment: .topTrailing)
        }
        .obscureContents(enabled: .constant(true))
    }
  }
  .environment(gridState)
}
