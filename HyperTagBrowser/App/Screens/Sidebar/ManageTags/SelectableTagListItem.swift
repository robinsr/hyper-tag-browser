// created on 4/23/25 by robinsr

import SwiftUI


struct SelectableTagListItem: View {
  typealias ItemTapFn = (UISelectionState.Intent, EventModifiers) -> Void
  
  @Environment(\.dispatcher) var dispatch
  
  var tag: FilteringTag
  @Binding var selections: Set<FilteringTag>
  
  func stashSelectedTag(_ tag: FilteringTag) {
    selections.remove(tag)
    dispatch(.stashTag(tag, into: .default))
  }
  
  func onTap(_ intent: UISelectionState.Intent, _ mods: EventModifiers) {
    switch (intent, mods) {
      
    case (.willSelect, .shift):
      selections.toggleExistence(tag)
      break;
      
    case (.willSelect, _):
      selections.removeAll()
      selections.insert(tag)
      break;
    
    case (.willDeselect, _):
      if selections.count == 1 {
        stashSelectedTag(tag)
      } else {
        selections.toggleExistence(tag)
      }
    
    default:
      return
    }
  }
  
  var itemState: UISelectionState {
    selections.contains(tag) ? .active : .none
  }

  var body: some View {
    SelectableItemView(itemState: itemState, onTap: self.onTap) { state in
      TagItemContent
        .contextMenu {
          TagItemContextMenu
        }
    }
    .fillFrame(.horizontal, alignment: .leading)
    .pointerStyle(.link)
  }
  
  var TagItemContent: some View {
    TagButton(for: tag, config: .init(
      size: .large,
      onTap: { _ in
        
      }
    ))
  }
  
  var TagItemContextMenu: some View {
    ContentTagContextMenu(
      for: tag,
      sections: [.refining, .editable, .searchable],
      onSelection: dispatch
    )
  }
}
