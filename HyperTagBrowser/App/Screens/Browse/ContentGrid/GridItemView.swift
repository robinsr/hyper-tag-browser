// created on 11/27/25 by robinsr

import Defaults
import Factory
import SwiftUI

struct GridItemView: View {
  
  private let logger = EnvContainer.shared.logger("GridItemView")
  
  @Default(.gridTileSize) var gridItemMinSize
  @Default(.showTagCountOnTiles) var showTagCount
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.cursorState) var cursorState
  @Environment(\.modifierKeys) var modState
  @Environment(\.dbContentItemTagMap) var dbTagCounts
  
  let item: ContentItem
  let index: Int
  
  func handleClickable(_ click: ClickableViewConfiguration.ClickType) {
    guard click == .right else { return }
    
    let isSelected = cursorState.contains(item)
    
    logger.emit(.debug, """
    Handling clickable:
      type: \(click)Click
      item: \(item.name.quoted)
      isSelected: \(isSelected)
    """)
    
    let itemTapped: CursorState.CursorActions = .tap(item, mods: modState.modifiers)
    
    if !isSelected {
      cursorState.dispatch(itemTapped, from: .folder)
    }
  }
  
  var body: some View {
    ThumbnailView(content: item, tileSize: CGSize(gridItemMinSize))
      .overlay {
        
        if showTagCount && item.conforms(to: .content) {
          TagCountOverlay(dbTagCounts[item.id] ?? 0)
        }
        
        if cursorState.manySelected && cursorState.contains(item) {
          SelectedOverlay
        }
        
        if item.index.visibility == .hidden {
          ItemVisibilityOverlay
        }
      }
      .clickable(onClick: handleClickable)
  }
  
  func TagCountOverlay(_ count: Int) -> some View {
    GridItemThumbnailOverlayView(icon: .tag, label: "\(count)", alignment: .bottomLeading)
      .fontWeight(.medium)
  }
  
  var SelectedOverlay: some View {
    GridItemThumbnailOverlayView(icon: .itemChecked, alignment: .bottomTrailing)
      .fontWeight(.bold)
      .foregroundStyle(.blue)
  }
  
  var ItemVisibilityOverlay: some View {
    GridItemThumbnailOverlayView(icon: .eyeslash, alignment: .topTrailing)
      .foregroundStyle(.red)
  }
  
  var ThumbnailIndicatorOverlay: some View {
    GridItemThumbnailOverlayView(icon: .camera, alignment: .topLeading)
      .fontWeight(.medium)
  }
}
