// created on 5/31/25 by robinsr

import SwiftUI

struct ToolbarDivider: View {
  var body: some View {
    HStack {
      Divider()
    }
    .padding(.horizontal, 12)
  }
}


struct ToolbarDividerViewModifier: ViewModifier {
  var placement: [PlacementLocation] = [.before, .after]
  
  func body(content: Content) -> some View {
    HStack {
      if placement.contains(.before) {
        ToolbarDivider()
      }
      
      content
      
      if placement.contains(.after) {
        ToolbarDivider()
      }
    }
  }
  
  enum PlacementLocation: String, CaseIterable {
    case before
    case after
  }
}

extension View {
  /**
   * Modifies the view to add a divider before and/or after it.
   */
  func toolbarDivider(placement: [ToolbarDividerViewModifier.PlacementLocation] = [.before, .after]) -> some View {
    modifier(ToolbarDividerViewModifier(placement: placement))
  }
}
