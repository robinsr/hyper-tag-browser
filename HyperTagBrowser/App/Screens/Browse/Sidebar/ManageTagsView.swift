// created on 10/31/24 by robinsr

import SwiftUI
import DebouncedOnChange
import IssueReporting
import CustomDump


struct ManageTagsView: View {
  @Environment(AppViewModel.self) var appVM
  @Environment(\.cursorState) var cursor
  @Environment(\.dispatcher) var dispatch
  
  @Binding var isPresented: Bool
  @State var searchquery = ""
  @State var selectedTags: Set<FilteringTag> = []
  @State var isStashDropTargeted = false
  @State var isStashHovered = false
  

  var body: some View {
    SectionView(isPresented: $isPresented, title: "Manage Tags") {
      VStack(alignment: .leading, spacing: 12) {
        
        TagStash
        
        SearchField(value: $searchquery, placeholder: "Search Tags")
          .controlSize(.extraLarge)
        
        VStack(alignment: .leading, spacing: 0) {
          TagSuggestions(
            searchText: $searchquery,
            numSuggestions: .constant(40),
            minTextNeeded: -1,
            searchDomains: [.attribution, .descriptive]
          ) { index, item in
            SelectableTagListItem(tag: item.asFilter, selections: $selectedTags)
          }
        }
      }
      .fillFrame(.horizontal)
    }
  }
  
  var TagStash: some View {
    FullWidth(alignment: .leading) {
      VStack(alignment: .center) {
        TagStashHeader
        
        Divider()
          .hidden(appVM.stashedTags.isEmpty)
        
        TagStashTags
          .hidden(appVM.stashedTags.isEmpty)
      }
      .padding(16)
    }
    .background {
      ImagePlaceholder(inset: 8)
        .background(DropZoneView(isActive: $isStashDropTargeted))
    }
    .dropDestination(for: FilteringTagSet.self) { tagset, _ in
      guard let droppedTags = tagset.first?.values else { return false }
      
      dispatch(.stashTags(droppedTags, into: .default))
      
      withAnimation {
        selectedTags.removeAll()
      }
      
      return true
      
    } isTargeted: { overTarget in
      isStashDropTargeted = overTarget
    }
    .onHover { isHovered in
      isStashHovered = isHovered
    }
    .overlay(alignment: .topTrailing) {
      ClearStashButton
        .visible(isStashHovered)
        .onHover { isHovered in
          isStashHovered = isHovered
        }
    }
    .fillFrame(.horizontal)
    .frame(minHeight: 0)
  }
  
  var TagStashHeader: some View {
    FullWidth(alignment: .center, spacing: 8) {
      Text("Stashed Tags")
      Image(systemName: "list.bullet.clipboard")
    }
    .pointerStyle(.grabIdle)
    .foregroundStyle(.tertiary)
    .draggable(FilteringTagSet(appVM.stashedTags.asArray)) {
      TagDraggablePreview(
        title: "Stashed Tags",
        tags: appVM.stashedTags.asArray)
    }
  }
  
  var TagStashTags: some View {
    HorizontalFlowView {
      ForEach(appVM.stashedTags.asArray, id: \.id, content: StashedTagButton)
    }
  }
  
  func StashedTagButton(_ tag: FilteringTag) -> some View {
    Button(tag.description, .tag) {
      dispatch(.unstashTag(tag, from: .default))
    }
    .buttonStyle(.smallpill)
  }
  
  var ClearStashButton: some View {
    Button("Clear Stash", .trash) {
      dispatch(.clearTagStash(id: .default))
    }
    .buttonStyle(.plain)
  }
}


#Preview("ManageTagsView", traits: .databaseContext, .defaultViewModel) {
  ManageTagsView(isPresented: .constant(true))
    .environment(CursorState())
    .frame(preset: .inspector)
}
