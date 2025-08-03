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

  let index: Int
  let bookmark: BookmarkItem

  var isActive: Binding<Bool> {
    // Determine if this bookmark is the current browse location
    .constant(browseLocation == bookmark.filepath.fileURL)
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
      isHovered: .constant(cursor.focusState(of: bookmark.content.pointer) == .hover),
      onTapAction: onSelect
    ) {
      HStack {
        Text(bookmark.name)
          .prefixWithFileIcon(.folder, presentation: .symbol)

        Spacer()

        if let shortcut = keyBinding {
          ShortcutHint(shortcut)
        }
      }
    }
    .acceptsContentDrops(moveItemTo: bookmark.content)
    .contextMenu {
      ContextMenuButton("Delete Bookmark", .trash) {
        dispatch(.deleteBookmark(bookmark))
      }
    }
    .modify(unless: keyBinding == nil) { view in
      view.buttonShortcut(binding: keyBinding, action: onSelect)
    }
  }

  private func ShortcutHint(_ shortcut: KeyBinding) -> some View {
    LabeledContent {
      Text(shortcut).monospaced()
    } label: {
      Label(.commandKey.variant(.circle.fill))
    }
    .labelStyle(.iconOnly)
  }
}
