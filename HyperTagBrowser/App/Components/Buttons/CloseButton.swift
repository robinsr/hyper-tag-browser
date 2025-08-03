// created on 11/14/24 by robinsr

import SwiftUI


struct CloseButton: View {
  let onClose: () -> Void
  
  var body: some View {
    Button {
      onClose()
    } label: {
      Label(SymbolIcon.close)
    }
    .buttonStyle(.plain)
    .labelStyle(.iconOnly)
    .contentShape(Rectangle())
    .padding(.horizontal, 8)
    .padding(.vertical, 8)
  }
}
