// created on 11/6/24 by robinsr

import SwiftUI


/**
 * A view to be used via the `.background` modifier. When active (such as
 * when a drop action can proceed) the view fills in with `Color.accentColor`,
 * otherwise fills with a muted dark color
 */
struct DropZoneView: View {
  @Binding var isActive: Bool
  
  var body: some View {
    RoundedRectangle(cornerRadius: 4.0)
      .fill(isActive
            ? Color.accentColor.opacity(0.3)
            : Color.black.opacity(0.2))
      .animation(.easeInOut(duration: 0.2), value: isActive)
  }
}
