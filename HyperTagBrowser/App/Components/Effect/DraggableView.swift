// created on 11/13/24 by robinsr

import SwiftUI


@available(*, deprecated, message: "Unused as of 2025-04-18")
struct DraggableView<Content: View> : View {
  @ViewBuilder let content: () -> Content
  
  @State private var offset = CGSize.zero
  @State private var translation = CGSize.zero
  
  var total: CGSize {
    offset.adding(translation)
  }
  
  var body: some View {
    content()
      .offset(x: total.width, y: total.height)
      .gesture(DragGesture()
        .onChanged { gesture in
          translation = gesture.translation
        }.onEnded { pos in
          offset = total
          translation = .zero
        })
  }
}
