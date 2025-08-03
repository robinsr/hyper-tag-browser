// created on 2/21/25 by robinsr

import SwiftUI


/**
 * Adds a `dropDestination` for `FilteringTagSet`, allowing it to accept Tags dragged from other view.
 * It dispatches the ``ModelActions/associateTags(_:to:)`` action with the dropped tags and content pointer
 */
struct FilteringTagDropDestination: ViewModifier {
  typealias Target = (any FileSystemContentItem & IdentifiableContentItem)
  
  @Environment(\.appViewModel) var appVM
  @Environment(\.cursorState) var cursorState
  
  var dropTarget: Target
  
  init(associateTo content: Target) {
    self.dropTarget = content
  }
  
  func body(content: Content) -> some View {
    content
      .dropDestination(for: FilteringTagSet.self) { droppedTags, _ in
        guard let tags = droppedTags.first?.values else { return false }
        
        //appVM.dispatch(.associateTags(tags, to: .one(associateTo)))
        appVM.dispatch(.associateTags(tags, to: .set(of: cursorState.selectedIds)))
        
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
    return modifier(FilteringTagDropDestination(associateTo: content))
  }
}
