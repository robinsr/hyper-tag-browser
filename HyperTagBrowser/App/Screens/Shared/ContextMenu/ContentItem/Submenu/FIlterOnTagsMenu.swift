// created on 3/16/25 by robinsr

import SwiftUI

struct FilterOnTagsMenu: View {
  @Environment(AppViewModel.self) var appVM
  
  var label: String = "Filter on..."
  let tags: [FilteringTag]
  let onSelection: DispatchFn
  
  var body: some View {
    Menu(label) {
      if tags.isEmpty {
        ContextMenuTextItem("Item has no tags")
      } else {
        ForEach(tags, id: \.self) { tag in
          Menu(tag.description) {
            ContentTagContextMenu(
              tag: tag,
              buttons: [ .filterIncluding, .filterExcluding]
            )
          }
        }
      }
    }
    .disabled(tags.isEmpty)
  }
}
