// created on 4/6/25 by robinsr

import SwiftUI


/**
 * Adds a `dropDestination` for URLs to a view, allowing it to accept URL drops.
 */
struct URLDropDestinationModifier: ViewModifier {
  var onUrlDrop: ([URL]) -> Void
  var onTargeted: (Bool) -> Void
  
  func body(content: Content) -> some View {
    content
      .dropDestination(for: URL.self) { droppedURLs, _ in
        onUrlDrop(droppedURLs)
        return true
      } isTargeted: { overTarget in
        onTargeted(overTarget)
      }
  }
}

extension View {
  
  /**
   * Adds the `URLDropDesinationModifier` modifier to the view, allowing it to accept URL drops.
   */
  func acceptsURLDrops(
    action fn: @escaping ([URL]) -> Void,
    onTargeted targetFn: @escaping (Bool) -> Void
  ) -> some View {
    modifier(URLDropDestinationModifier(onUrlDrop: fn, onTargeted: targetFn))
  }
}
