// created on 1/4/25 by robinsr

import SwiftUI

/**
 * Adds a `dropDestination` for the ``ContentPointers`` type, handling drag-and-drop operations related
 * to moving content items. Dispatches the ``ModelActions/updateIndex(_:)`` action
 */
struct ContentItemsDropDestination: ViewModifier {
  typealias Target = (any FileSystemContentItem & IdentifiableContentItem)
  
  @Environment(AppViewModel.self) var appVM
  @Environment(\.cursorState) var cursorState

  
  var dropTarget: Target
  
  func body(content: Content) -> some View {
    content
      .dropDestination(for: ContentPointers.self) { droppedItems, _ in
        guard let droppedPointers = droppedItems.first?.values else { return false }

        // Get set of ContentItem IDs dropped, excluding the drop target's ID
        let droppedContentIds = droppedPointers.ids.filter { $0 != dropTarget.id }

        appVM.dispatch(
          .updateIndex(
            .location(of: droppedContentIds, with: dropTarget.filepath)
          ))

        return true
      } isTargeted: { overTarget in
        if overTarget {
          cursorState.setHoveringTarget(to: dropTarget.pointer, with: ContentItem.self)
        } else {
          cursorState.clearHoveringTarget(of: dropTarget.pointer, with: ContentItem.self)
        }
      }
  }
}

extension View {

  /**
   * Adds the `ContentItemsDropDestination` modifier to the view, allowing it to accept ContentItem drops
   */
  @ViewBuilder
  func acceptsContentDrops(moveItemTo content: ContentItemsDropDestination.Target) -> some View {
    if content.conforms(to: .folder) {
      modifier(ContentItemsDropDestination(dropTarget: content))
    } else {
      self
    }
  }
}
