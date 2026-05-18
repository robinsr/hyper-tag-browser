// created on 2/3/25 by robinsr

import SwiftUI


/**
 * A "Shape" used as a background for selectable items in a grid.
 */
struct SelectableGridItemShape: View {
  var state: UISelectionState
  var borderWidth: CGFloat
  let cornerRadius: CGFloat = 8
  var lineWidth: CGFloat { borderWidth }
  var inset: CGFloat { borderWidth / 2 }
  
  var body: some View {
    RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
      .inset(by: inset)
      .stroke(state.colors.stroke, style: StrokeStyle(lineWidth: lineWidth))
      .fill(state.colors.fill)
  }
}


/**
 * A "Shape" used as a background for selectable items in a list.
 */
struct SelectableListItemShape: View {
  var state: UISelectionState
  
  var body: some View {
    RoundedRectangle(cornerRadius: 4, style: .circular)
      .inset(by: 2)
      .stroke(state.colors.stroke, style: StrokeStyle(lineWidth: 2))
      .fill(state.colors.fill)
      .opacity(0.5)
  }
}
