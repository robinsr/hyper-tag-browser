// created on 12/26/25 by robinsr

import SwiftUI


struct DraggableContentItemModifier: ViewModifier {
  @Environment(\.cursorState) var cursorState: CursorState
  
  let contentItem: ContentItem
  
  var singleItemTransfer: [ContentItem] {
    return [contentItem]
  }
  
  var transferItems: [ContentItem] {
    guard contentItem.conforms(to: .content) else {
        // Only allows items with the UTType of `public.content` to be dragged.
        // TODO: Revisit this; Currently disallows dragging `public.folder` types
      return []
    }
    
    if (cursorState.noneSelected) {
        // For content items, enable single-file, file-to-folder transfers
      return singleItemTransfer
    }
    
    if (cursorState.anySelected && !cursorState.contains(contentItem)) {
        // When dragging an item not in the selection, allow dragging it as a single item
      return singleItemTransfer
    }
    
    if (cursorState.anySelected && cursorState.contains(contentItem)) {
        // For content items, enable cursor-based file-to-folder transfers
      return cursorState.selection
    }
    
    return []
  }
  
  
  func body(content: Content) -> some View {
    content
      .modify(when: transferItems.notEmpty) { $0
        .draggable(transferItems.transferables) {
          ContentDragPreview(items: transferItems)
        }
      }
  }
}
  
  
extension View {
  
  /// Returns a drag-enabled view, deriving the transferable object from the provided
  /// `ContentItem`.
  func draggable(contentItem content: ContentItem) -> some View {
    modifier(DraggableContentItemModifier(contentItem: content))
  }
}
