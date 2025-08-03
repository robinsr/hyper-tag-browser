// created on 6/9/25 by robinsr

import SwiftUI

struct BookmarksList: View {
  @Environment(\.dbBookmarks) var bookmarks
  
  @Binding var isPresented: Bool
  
  var indexedBookmarks: [(index: Int, bookmark: BookmarkItem)] {
    bookmarks.prefix(12).collect().indexed
  }
  
  var body: some View {
    SectionView(isPresented: $isPresented) {
      ListItems
    } label: {
      Text("Bookmarks")
        .accessibilityLabel("Show bookmarks")
    }
  }
  
//  var _ListItems: some View {
//    List(indexedBookmarks, id: \.bookmark.id) { index, bookmark in
//      BookmarksListItem(index: index, bookmark: bookmark)
//        .id(bookmark.id)
//    }
//  }
  
  var ListItems: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(indexedBookmarks, id: \.bookmark.id) { index, bookmark in
        BookmarksListItem(index: index, bookmark: bookmark)
          .id(bookmark.id)
      }
    }
  }
}

#Preview("Bookmarks", traits: .defaultViewModel, .previewSize(.inspector)) {
  BookmarksList(isPresented: .constant(true))
    .environment(\.dbBookmarks, TestData.testBookmarks)
}
