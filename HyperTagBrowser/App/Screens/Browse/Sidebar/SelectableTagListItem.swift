// created on 4/23/25 by robinsr

import SwiftUI


struct SelectableTagListItem: View {
  @Environment(AppViewModel.self) var appVM
  @Environment(\.dispatcher) var dispatch
  
  var tag: FilteringTag
  @Binding var selections: Set<FilteringTag>
  
  func stashSelectedTag(_ tag: FilteringTag) {
    selections.remove(tag)
    dispatch(.stashTag(tag, into: .default))
  }
  
  func tapHandler(for tag: FilteringTag) -> (SelectableItemView.Interaction, EventModifiers) -> Void {
    { interaction, mods in
      switch (interaction, mods) {
        
      case (.select, .shift):
        selections.toggleExistence(tag)
        break;
        
      case (.select, _):
        selections.removeAll()
        selections.insert(tag)
        break;
      
      case (.isSelected, _):
        if selections.count == 1 {
          stashSelectedTag(tag)
        } else {
          selections.toggleExistence(tag)
        }
      
      default:
        return
      }
    }
  }
  
  var selectionEmpty: Bool { selections.isEmpty }
  var selectionCount: Int { selections.count }
  var isInSelection: Bool { selections.contains(tag) }
  
  var body: some View {
    SelectableItemView(
      itemState: selections.contains(tag) ? .active : .none,
      onTap: tapHandler(for: tag)
    ) { state in
        TagLabel(tag: tag)
          .padding(.horizontal, 10)
          .padding(4)
          .fillFrame(.horizontal, alignment: .leading)
          .background(state.colors.fill)
          .contentShape(Rectangle())
          .contextMenu {
            ContentTagContextMenu(
              tag: tag,
              sections: [.refining, .editable, .searchable],
              onSelection: dispatch
            )
          }
          
          // Multi-Tag Drag, dragged from one of the selected tags
          .modify(when: !selectionEmpty && isInSelection) { view in
            view.draggable(FilteringTagSet(selections.asArray)) {
              TagDraggablePreview(title: "Tag set \(selectionCount)", tags: selections.asArray)
            }
          }
        
          // Multi-Tag Drag, dragged from another unselected tag
          .modify(when: !selectionEmpty && !isInSelection) { view in
            view.draggable(FilteringTagSet(tag)) {
              TagDraggablePreview(title: "Single tag: \(tag.value)", tags: [tag])
            }
          }
        
          // Single Tag Drag
          .modify(when: selectionEmpty) { view in
            view.draggable(FilteringTagSet(tag)) {
              TagDraggablePreview(title: "Single tag: \(tag.value)", tags: [tag])
            }
          }
      }
      .fillFrame(.horizontal, alignment: .leading)
      .pointerStyle(.link)
  }
}

