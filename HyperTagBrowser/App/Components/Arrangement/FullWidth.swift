// created on 12/6/24 by robinsr

import SwiftUI

struct FullWidth<Content: View>: View {
  var alignment: Alignment = .leading
  var spacing: CGFloat = 0.0
  
  @ViewBuilder var content: () -> Content
  
  var vAlign: VerticalAlignment {
    alignment.vertical
  }
  
  var hAlign: HorizontalAlignment {
    alignment.horizontal
  }
  
  var body: some View {
    HStack(spacing: spacing) {
      content()
    }
    .fillFrame(.horizontal, alignment: alignment)
  }
}

struct FullWidthSplit<LContent: View, RContent: View>: View {
  var alignment: Alignment = .leading
  var spacing: CGFloat = 0.0
  
  @ViewBuilder var leading: () -> LContent
  @ViewBuilder var trailing: () -> RContent

  var body: some View {
    FullWidth(alignment: alignment, spacing: spacing) {
      leading()
      Spacer()
      trailing()
    }
  }
}

typealias HStackSplit = FullWidthSplit
