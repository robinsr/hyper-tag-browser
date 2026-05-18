// created on 10/15/24 by robinsr

import SwiftUI


/**
 * View for displaying a ``BookmarkItem``
 */
struct BookmarksListItem: View {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  @Environment(\.location) var browseLocation
  @Environment(\.isPresented) var isShowing
  @Environment(\.cursorState) var cursor
  
  @State var isHovered = false

  let index: Int
  let bookmark: BookmarkItem

  var isActive: Binding<Bool> {
    // Determine if this bookmark is the current browse location
    .constant(browseLocation == bookmark.filepath.fileURL)
  }
  
  var isBrowsable: Bool {
    bookmark.filepath.isBrowsable
  }
  
  var isUbiquitousItem: Bool {
    bookmark.filepath.fileURL.isUbiquitousItem
  }

  var keyBinding: KeyBinding? {
    index < 10 ? .numShortcut(index, .command) : nil
  }

  func onSelect() {
    // Navigate to the bookmark's URL
    navigate(.folder(bookmark.filepath))
  }
  

  var body: some View {
    SidebarButton(
      isActive: isActive,
      isHovered: $isHovered,
      activateOn: .inactive,
      onTapAction: onSelect
    ) {
      ButtonContent
    }
    .bindHover(to: $isHovered)
    .acceptsContentDrops(moveItemTo: bookmark.content)
    .contextMenu {
      ButtonContextMenuItems
    }
  }
  
  var ButtonContent: some View {
    HStack {
      Text(bookmark.name)
        .prefixWithFileIcon(.folder, presentation: .symbol)
        .foregroundColor(isBrowsable ? .textColor : .red)
      
      Label(.icloud.variant(.circle.fill))
        .visible(isUbiquitousItem)

      Spacer()

      if let shortcut = keyBinding {
        KeyBindingHintView(binding: shortcut)
          .opacity(isHovered ? 1 : 0.66)
          .buttonShortcut(binding: shortcut, action: onSelect)
      }
    }
  }
  
  var ButtonContextMenuItems: some View {
    ContextMenuButton("Delete Bookmark", .trash) {
      dispatch(.deleteBookmark(bookmark))
    }
  }
}


#Preview("Bookmark List Item", traits: .app, .size(.init(width: 400, height: 150))) {
  VStack(alignment: .leading, spacing: 2) {
    BookmarksListItem(index: 0, bookmark: TestData.cloudBookmarks[0])
  }
}
