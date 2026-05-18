// created on 2/21/25 by robinsr

import SwiftUI


/**
 * Adds a `dropDestination` for `FilteringTagSet`, allowing it to accept Tags dragged from other view.
 * It dispatches the ``ModelActions/associateTags(_:to:)`` action with the dropped tags and content pointer
 */
struct FilteringTagDropDestination: ViewModifier {
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.cursorState) var cursorState
  
  var dropTarget: ContentItem
  
  init(droppedOn contentItem: ContentItem) {
    self.dropTarget = contentItem
  }
  
  func body(content: Content) -> some View {
    content
      .dropDestination(for: FilteringTagSet.self) { droppedTags, _ in
        guard let tags = droppedTags.first?.values else { return false }
        
        let cursorIds = cursorState.selectedIds.map(\.contentId)
        let targetId = dropTarget.id
        
        if cursorIds.contains(targetId) {
          // associate to all cursor-selected items
          dispatch(.associateTags(tags, to: .include(cursorIds)))
        } else {
          // associate to just the drop target item
          dispatch(.associateTags(tags, to: .only(targetId)))
        }
        
        return true
      } isTargeted: { overTarget in
        //onTargeted(overTarget)
        
        if overTarget {
          cursorState.setHoveringTarget(to: dropTarget.pointer, with: FilteringTag.self)
        } else {
          cursorState.clearHoveringTarget(of: dropTarget.pointer, with: FilteringTag.self)
        }
      }
  }
}

extension View {
  
  /**
   * Adds the `FilteringTagDropDestination` modifier to the view, allowing it to accept tag drops
   */
  func acceptsTagDrops(addTo content: ContentItem) -> some View {
    return modifier(FilteringTagDropDestination(droppedOn: content))
  }
}
