// created on 4/23/25 by robinsr

import SwiftUI


struct GridItemThumbnailOverlayView: View {
  @Environment(\.photoGridState) var gridState
  
  var icon: SymbolIcon = .info
  var label: String = ""
  var alignment: Alignment = .topLeading

  var body: some View {
    ThumbnailOverlayView(
      icon: icon,
      iconFont: gridState.iconFont,
      label: label,
      alignment: alignment
    )
    .padding(gridState.itemWidth / 24)
  }
}
