// created on 2/9/25 by robinsr

import SwiftUI

struct SheetBottomFormModifier: ViewModifier {
  @Environment(\.sheetPadding) var sheetPadding
  
  func body(content: Content) -> some View {
    content
      .padding(sheetPadding)
      .background(Color(.controlBackgroundColor))
      .padding(.leading, -sheetPadding.leading)
      .padding(.trailing, -sheetPadding.trailing)
      .padding(.bottom, -sheetPadding.bottom)
      .transition(
        .move(edge: .bottom)
        .combined(with: .offset(x: 0, y: sheetPadding.top)))
  }
}
extension View {
  func sheetBottomForm() -> some View {
    modifier(SheetBottomFormModifier())
  }
}
