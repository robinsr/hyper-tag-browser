// created on 5/2/25 by robinsr

import SwiftUI


/**
 * A `HStack` that automatically adds spacers between its elements
 */
struct SpacedHStack<Content: View>: View {
  
  var alignment: Alignment = .leading
  var spacing: CGFloat = 0.0
  
  @ViewBuilder
  let content: Content
  
  var body: some View {
    HStack {
      Group(subviews: content) { subviews in
        if !subviews.isEmpty {
          subviews[0]
        }
        
        ForEach(subviews[1...], id: \.id) { subview in
          Spacer()
          subview
        }
      }
    }
    .fillFrame(.horizontal, alignment: alignment)
  }
}
