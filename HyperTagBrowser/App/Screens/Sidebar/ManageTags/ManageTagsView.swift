// created on 10/31/24 by robinsr

import CustomDump
import DebouncedOnChange
import Factory
import SwiftUI


struct ManageTagsView: View {
  
  @Environment(\.cursorState) var cursor
  @Environment(\.dispatcher) var dispatch
  
  @Binding var isPresented: Bool
  @State var searchquery = ""
  @State var selectedTags: Set<FilteringTag> = []
  @State var isStashDropTargeted = false
  @State var isStashHovered = false
  
  @State private var suggestions = SuggestionViewModel()
  @State private var stash = TagStashViewModel()
  

  var body: some View {
    SectionView("Manage Tags", isPresented: $isPresented) {
      VStack(alignment: .leading, spacing: 12) {
        TagStash
        SearchTagControls
        TagListItems
      }
      .fillFrame(.horizontal)
      .focusedValue(\.tagSelection, selectedTags)
    }
    .onChange(of: searchquery, debounceTime: .milliseconds(150)) {
      suggestions.searchText = searchquery.isEmpty ? "%" : searchquery
      suggestions.userDidChangeQuery()
    }
    .task {
      suggestions.itemLimit = 100
      suggestions.searchText = "%"
      suggestions.userDidChangeQuery()
    }
  }
  
  var SearchTagControls: some View {
    SearchField(value: $searchquery, placeholder: "Search Tags")
      .controlSize(.extraLarge)
  }
  
  var TagListItems: some View {
    HorizontalFlowView {
      ForEach(suggestions.indexed, id: \.0) { index, item in
        TagButton(for: item) {
          TagButtonConfiguration(
            size: .large,
            variant: .secondary,
            counts: .always,
            draggable: true,
            menu: .tagMenu(when: .taggingContent),
            onMenuItem: { dispatch($0) },
            onLongPress: { tag in
              dispatch(.showSheet(.renameTagSheet(tag: tag, scope: .all)))
            },
            onTap: { tag in
              stash.stash(tag: tag, in: .default)
            },
          )
        }
        .draggable(filteringTag: item.asFilter)
        //.focusable(false) // disabling canFocus, will it do anything?
        //.focusEffectDisabled(true)
      }
    }
  }
  
  
  var TagStash: some View {
    FullWidth(alignment: .leading) {
      VStack(alignment: .center) {
        TagStashHeader
        
        Divider()
          .hidden(stash.isEmpty)
        
        TagStashTags
          .hidden(stash.isEmpty)
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
    .draggable(FilteringTagSet(stash.items)) {
      TagDraggablePreview(title: "Stashed Tags", tags: stash.items)
    }
  }
  
  var TagStashTags: some View {
    HorizontalFlowView {
      ForEach(stash.items, id: \.id) { tag in
        StashedTagButton(tag)
      }
    }
  }
  
  func StashedTagButton(_ tag: FilteringTag) -> some View {
    TagButton(for: tag) {
      TagButtonConfiguration(
        counts: .never,
        menu: .tagMenu(when: .taggingContent),
        onMenuItem: dispatch,
        onTap: { _ in
          stash.unstash(tag: tag, from: .default)
        }
      )
    }
  }
  
  var ClearStashButton: some View {
    Button("Clear Stash", .trash) {
      stash.clearTagStash(id: .default)
    }
    .buttonStyle(.plain)
  }
}


#Preview("ManageTagsView", traits: .dbCtx, .app, .size(.inspector)) {
  ManageTagsView(isPresented: .constant(true))
    .fillFrame(.both, alignment: .top)
    .environment(CursorState())
}
