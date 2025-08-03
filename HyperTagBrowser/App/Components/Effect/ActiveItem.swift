// created on 9/24/24 by robinsr

import SwiftUI



/**
 * A View that adds a visual indication of the content's selection state.
 */
struct SelectableItemView<Content: View>: View {
  typealias ItemState = SelectionItem.State
  typealias Interaction = SelectionItem.Interaction
  
  let itemState: SelectionItem.State
  let insetAmount: CGFloat
  let onTap: (Interaction, EventModifiers) -> Void
  let content: (ItemState) -> (Content)
  
  
  init(
    itemState: @autoclosure () -> SelectionItem.State = .none,
    insetAmount: CGFloat = 0,
    onTap: @escaping ((Interaction, EventModifiers) -> Void) = { _,_ in },
    @ViewBuilder content: @escaping (ItemState) -> Content
  ) {
    self.itemState = itemState()
    self.insetAmount = insetAmount
    self.onTap = onTap
    self.content = content
  }
  
  @Environment(\.modifierKeys) var modState
  
  //var itemState: ItemState {
  //  if hoverWhen { return .hover }
  //  if activeWhen { return .active }
  //  if dimmedWhen { return .dimmed }
  //  return .none
  //}
  
  func onItemTap(_ itemState: ItemState) {
    switch itemState {
    case .active:
      return onTap(.isSelected, modState.modifiers)
    default:
      return onTap(.select, modState.modifiers)
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
