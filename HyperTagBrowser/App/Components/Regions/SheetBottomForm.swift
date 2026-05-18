// created on 2/9/25 by robinsr

import SwiftUI

struct SheetBottomFormModifier: ViewModifier {
  @Environment(\.sheetPadding) var sheetPadding
  
  var insets: EdgeInsets? = nil
  
  var padding: EdgeInsets {
    insets ?? sheetPadding
  }
  
  func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(Color(.controlBackgroundColor))
      .padding(.leading, -padding.leading)
      .padding(.trailing, -padding.trailing)
      .padding(.bottom, -padding.bottom)
      .transition(
        .move(edge: .bottom)
        .combined(with: .offset(x: 0, y: padding.top)))
  }
}


extension View {
  func sheetBottomForm(insets: EdgeInsets? = nil) -> some View {
    modifier(SheetBottomFormModifier(insets: insets))
  }
}
