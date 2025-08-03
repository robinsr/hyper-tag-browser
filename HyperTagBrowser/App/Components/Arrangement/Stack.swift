// created on 1/11/25 by robinsr

import SwiftUI


/**
 * A simple view that stacks its children vertically or horizontally
 *
 * - Parameters:
 * - `axis`: The axis along which to stack the children; `.vertical` or `.horizontal`
 * - `align`: The alignment of the children along the axis
 * - `spacing`: The spacing between the children
 */
struct StackView<Content: View>: View {
  var axis: Axis = .vertical
  var direction: SubviewOrdering = .normal
  var align: Alignment = .center
  var spacing: CGFloat = 0
  
  @ViewBuilder var content: () -> Content
  
  var body: some View {
    let layout = axis == .vertical
    ? AnyLayout(VStackLayout(alignment: align.horizontal, spacing: spacing))
    : AnyLayout(HStackLayout(alignment: align.vertical, spacing: spacing))
    
    return
      Group(subviews: content()) { subviews in
        layout {
          switch direction {
          case .normal:
            ForEach(subviews, id: \.id) { subview in
              subview
            }
          case .reversed:
            ForEach(subviews.reversed(), id: \.id) { subview in
              subview
            }
          }
        }
      }
  }
}
