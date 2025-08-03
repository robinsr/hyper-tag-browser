// created on 12/22/24 by robinsr

import SwiftUI

/**
 * A image displayer view that uses a **fixed-size** SwiftUI `Image` view and
 * resizes the image manually to fit the view bounds.
 */
@available(*, deprecated, message: "Unused as of 2025-06-03")
struct SimpleFileURLThumbnailView: View {
  let fileURL: URL
  var size: CGSize = CGSize(widthHeight: 100)

  @State var thumbnail: CGImage = .empty

  func resize() {
    if let cgImage = ImageDisplay.sized(size, .fill).cgImage(url: fileURL) {
      thumbnail = cgImage
    }
  }

  var body: some View {
    Image(decorative: thumbnail, scale: 1.0, orientation: .up)
      .fixedSize()
      .aspectRatio(contentMode: .fill)
      .frame(width: size.width, height: size.height)
      .clipped()
      .aspectRatio(1, contentMode: .fit)
      .onAppear {
        resize()
      }
  }
}

/**
 * A image displayer view that uses a **Resizable** SwiftUI `Image` View
 */
struct SimpleResizableThumbnailView: View {
  let cgImage: CGImage?

  var body: some View {
    Image(decorative: cgImage ?? .empty, scale: 1.0, orientation: .up)
      .resizable()
      .aspectRatio(contentMode: .fill)
      .clipped()
      .aspectRatio(1, contentMode: .fit)
  }
}
