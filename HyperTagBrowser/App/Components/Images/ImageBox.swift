// created on 2/5/25 by robinsr

import AppKit
import SwiftUI


struct ImageBox: View {
  let title: String
  let nsImage: NSImage
  let resized: Bool
  
  init(_ title: String = "", nsImage: NSImage, resizable: Bool = false) {
    self.title = title
    self.nsImage = nsImage
    self.resized = resizable
  }
  
  var body: some View {
    GroupBox(title) {
      Image(nsImage: nsImage)
        .modify(when: resized) { view in
          view
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
      
      Text(verbatim: "Size: \(nsImage.size.formatted)")
    }
  }
}
