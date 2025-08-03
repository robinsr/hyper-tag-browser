// created on 2/3/25 by robinsr

import SwiftUI


/**
 * A "Shape" used as a background for selectable items in a grid.
 */
struct SelectableGridItemShape: View {
  var state: SelectionItem.State
  var borderWidth: CGFloat
  let cornerRadius: CGFloat = 8
  var lineWidth: CGFloat { borderWidth }
  var inset: CGFloat { borderWidth / 2 }
  
  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
      .inset(by: inset)
      .stroke(state.suggestedStrokeColor, style: StrokeStyle(lineWidth: lineWidth))
      .fill(state.suggestedFillColor)
  }
}


/**
 * A "Shape" used as a background for selectable items in a list.
 */
struct SelectableListItemShape: View {
  var state: SelectionItem.State
  
  var body: some View {
    RoundedRectangle(cornerRadius: 4, style: .circular)
      .inset(by: 2)
      .stroke(state.suggestedStrokeColor, style: StrokeStyle(lineWidth: 2))
      .fill(state.suggestedFillColor)
      .opacity(0.5)
  }
}
