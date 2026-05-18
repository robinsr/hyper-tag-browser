// created on 9/24/24 by robinsr

import SwiftUI



/**
 * A View that adds a visual indication of the content's selection state.
 */
struct SelectableItemView<Content: View>: View {
  typealias UIIntention = UISelectionState.Intent
  typealias ItemTapFn = (UISelectionState.Intent, EventModifiers) -> Void
  
  @Environment(\.modifierKeys) var modState
  
  let itemState: UISelectionState
  let insetAmount: CGFloat
  let onTap: ItemTapFn
  let content: (UISelectionState) -> (Content)
  
  
  init(
    itemState: @autoclosure () -> UISelectionState = .none,
    insetAmount: CGFloat = 0,
    onTap: @escaping (UISelectionState.Intent, EventModifiers) -> Void = { _,_ in },
    @ViewBuilder content: @escaping (UISelectionState) -> Content
  ) {
    self.itemState = itemState()
    self.insetAmount = insetAmount
    self.onTap = onTap
    self.content = content
  }
  
  func onItemTap(_ itemState: UISelectionState) {
    switch itemState {
    case .active:
      return onTap(.willDeselect, modState.modifiers)
    default:
      return onTap(.willSelect, modState.modifiers)
    }
  }
  
  var body: some View {
    content(itemState)
      .padding(insetAmount)
      .contentShape(
        Rectangle()
      )
      .onTapGesture {
        onItemTap(itemState)
      }
  }
}
