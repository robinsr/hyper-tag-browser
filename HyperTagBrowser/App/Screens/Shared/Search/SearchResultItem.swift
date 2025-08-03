// created on 12/25/24 by robinsr

import Defaults
import Factory
import Files
import SwiftUI


struct SearchResultItem: View {
  let TAG_LIMIT = 10
  let thumbnailSize = CGSize(widthHeight: 150)
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  
  @Injected(\IndexerContainer.indexService) var indexer
  @Injected(\Container.spotlightService) var spotlight
  
  var content: ContentItem
  
  var searched: [String] = []
  
  var queryLocation: URL = Defaults[.profileOpenTo]
  
  var updateQuery: (SearchTerm) -> () = { _ in }
  
  @State var showMetadataSheet = false
  
  var tags: [FilteringTag] {
    content.tags.prefix(TAG_LIMIT).collect()
  }
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ResultThumbnail
      ResultDetails
    }
  }
  
  var isHiddenItem: Binding<Bool> {
    .constant(content.index.visibility == .hidden)
  }
  
  var ResultThumbnail: some View {
    ThumbnailView(content: content, tileSize: thumbnailSize)
      .clipped()
      .frame(width: 150)
      .obscureContents(enabled: isHiddenItem)
      .overlay(alignment: .topLeading) {
        ResultsInfoOverlay
      }
      .contextMenu {
        SearchResultContextMenu
      }
      .environment(\.releventContentType, content.index.type)
  }
  
  @ViewBuilder
  var SearchResultContextMenu: some View {
    ContextMenuButton("Reindex Item", .database) {
      dispatch(.updateSearchIndex(with: [content.pointer]))
    }
    ContextMenuButton("Remove From Search Index", .trash) {
      dispatch(.deleteFromSearchIndex(items: [content.pointer]))
    }
  }
  
  var ResultDetails: some View {
    VStack(alignment: .leading, spacing: 12) {
      Group {
        NavigateToItemButton
        NavigateToFolderButton(
          location: content.location,
          relativeTo: queryLocation.filepath.directory
        )
      }
      .buttonStyle(.weblink)
      ResultItemTags
    }
  }
  
  var ResultItemTags: some View {
    HorizontalFlowView(vAlign: .firstTextBaseline, itemSpacing: 3, rowSpacing: 8) {
      TagButton(
        for: .created(.init(date: content.index.created, bounds: .on)),
        config: tagButtonConfig
      )
      
      ForEach(tags, id: \.id) { tag in
        TagButton(
          for: tag,
          config: .init(
            variant: .primary,
            contextMenuConfig: .sections([.refining, .searchable]),
            contextMenuDispatch: { action in
              switch action {
              case .addFilter(_,_):
                dispatch(action)
                dispatch(.showSheet(.none))
              case .searchForTerm(let term):
                updateQuery(term)
              case .searchForTag(let tag):
                updateQuery(tag.asSearchTerm)
              default:
                dispatch(action)
              }
            },
            onTap: { tag in
              updateQuery(tag.asSearchTerm)
            }
          )
        )
      }
      
      Text(verbatim: "and \(tags.count - TAG_LIMIT) more...")
        .font(.caption)
        .visible(tags.count - TAG_LIMIT > 0)
    }
  }
  
  var ResultsInfoOverlay: some View {
    ThumbnailOverlayView(icon: .info, iconFont: .system(size: 16))
      .padding(8)
      .contentShape(Rectangle())
      .onTapGesture {
        showMetadataSheet.toggle()
      }
      .sheetView(isPresented: $showMetadataSheet, style: JSONView.presentation) {
        JSONView(object: .constant(spotlight.prepareItemForIndex(content)))
      }
  }
  
  var NavigateToItemButton: some View {
    Button {
      dispatch(.showSheet(.none))
      navigate(.content(content.pointer))
    } label: {
      HighlightedTextView(content.name, emphasize: searched, emStyle: .highlighter)
        .multilineTextAlignment(.leading)
        .styleClass(.body)
        .selectable()
        .prefixWithFileIcon(content.index.url, size: 16)
    }
  }
  
  var tagButtonConfig: TagButtonConfiguration {
    .init(
      size: .small,
      variant: .primary,
      contextMenuConfig: .whenSuggestedDuringSearch,
      contextMenuDispatch: { action in
        switch action {
        case .addFilter(_,_):
          dispatch(action)
          dispatch(.showSheet(.none))
        case .searchForTerm(let term):
          updateQuery(term)
        case .searchForTag(let tag):
          updateQuery(tag.asSearchTerm)
        default:
          dispatch(action)
        }
      })
  }
}
