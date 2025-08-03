// created on 1/4/25 by robinsr

import SwiftUI
import SwiftUIIntrospect


/**
 * A scroll view that uses the overlay style on macOS
 */
struct OverlayVerticalScrollView<Content: View>: View {
  @ViewBuilder var content: () -> (Content)
  
  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      content()
    }
    .scrollBounceBehavior(.always)
    .scrollContentBackground(.hidden)
    .background(.clear)
    .introspect(.scrollView, on: .macOS(.v10_15, .v11, .v12, .v13, .v14, .v15)) { (scrollView: NSScrollView) in
      scrollView.hasVerticalScroller = true
      scrollView.hasHorizontalScroller = false
      
      if #available(macOS 10.16, *) {
          scrollView.borderType = .lineBorder
          scrollView.scrollerStyle = .overlay
      } else {
          scrollView.borderType = .bezelBorder
      }
      
      scrollView.autoresizingMask = [.width, .height]
      scrollView.drawsBackground = false
      scrollView.backgroundColor = .clear
      
      scrollView.layer?.borderColor = NSColor.clear.cgColor
    }
  }
}
