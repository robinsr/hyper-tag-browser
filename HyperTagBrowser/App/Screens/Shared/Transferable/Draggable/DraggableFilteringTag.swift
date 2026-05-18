// created on 1/12/26 by robinsr

import SwiftUI

struct DraggableFilteringTag: ViewModifier {
  @Environment(\.cursorState) var cursorState: CursorState
  @FocusedValue(\.tagSelection) var tagsSelected
  
  var selections: [FilteringTag] {
    tagsSelected?.asArray ?? []
  }
  
  var selectionEmpty: Bool {
    selections.isEmpty
  }
  
  var selectionCount: Int {
    selections.count
  }
  
  var isInSelection: Bool {
    selections.contains(tag)
  }
  
  let tag: FilteringTag
  
  func body(content: Content) -> some View {
    content
      // Multi-Tag Drag, dragged from one of the selected tags
      .modify(when: !selectionEmpty && isInSelection) { view in
        view.draggable(FilteringTagSet(selections)) {
          TagDraggablePreview(title: "\("Tag", qty: selectionCount)", tags: selections)
        }
      }
    
      // Multi-Tag Drag, dragged from another unselected tag
      .modify(when: !selectionEmpty && !isInSelection) { view in
        view.draggable(FilteringTagSet(tag)) {
          TagDraggablePreview(title: tag.value, tags: [tag])
        }
      }
    
      // Single Tag Drag
      .modify(when: selectionEmpty) { view in
        view.draggable(FilteringTagSet(tag)) {
          TagDraggablePreview(title: tag.value, tags: [tag])
        }
      }
  }
}


extension View {
  
  /// Returns a drag-enabled view, deriving the transferable object from the provided
  /// `ContentItem`.
//  func draggable(filteringTag tag: FilteringTag) -> some View {
//    modifier(DraggableFilteringTagSet(tag: tag))
//  }
}

