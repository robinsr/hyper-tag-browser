// created on 10/21/24 by robinsr

import SwiftUI

struct ImagePlaceholder<Content: View>: View {

  var inset: Double
  var content: Content
  
  let dashedStroke = StrokeStyle(lineWidth: 4, lineCap: .square, dash: [7], dashPhase: 2.0)
  
  init(
    inset: Double = 4.0,
    @ViewBuilder content: @escaping () -> (Content) = { EmptyView() }
  ) {
    self.inset = inset
    self.content = content()
  }

  var body: some View {
    ZStack(alignment: .center) {
      RoundedRectangle(cornerSize: CGSize(8))
        .strokeBorder(.black.opacity(0.2), style: dashedStroke)
        .padding(inset)
      content
    }
  }
}
