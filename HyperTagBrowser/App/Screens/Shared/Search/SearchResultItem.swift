// created on 12/25/24 by robinsr

import Defaults
import Factory
import Files
import SwiftUI


struct SearchResultItem: View {
  let TAG_LIMIT = 10
  let thumbnailSize = CGSize(widthHeight: 150)
  
  @Environment(SearchModel.self) var model
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  
  @Injected(\Container.spotlightService) var spotlight
  
  var content: ContentItem
  
  @State var showMetadataSheet = false
  
  func onTagMenuItem(_ action: ModelActions) {
    switch action {
    case .addFilter(_,_):
      dispatch(action)
      dispatch(.showSheet(.none))
    case .searchForTerm(let term):
      model.appendTerm(term)
    case .searchForTag(let tag):
      model.appendTerm(tag.asSearchTerm)
    default:
      dispatch(action)
    }
  }
  
  func onTagTap(_ tag: FilteringTag) {
    if (tag.domain.oneOf(.descriptive, .attribution)) {
      model.appendTerm(tag.asSearchTerm)
    }
  }
  
  var searched: [String] {
    model.queryString.split()
  }
  
  var queryLocation: URL {
    model.queryLocation
  }
  
  var tags: [FilteringTag] {
    content.tags.prefix(TAG_LIMIT).collect()
  }
  
  var createdOnTag: FilteringTag {
    .created(.onDate(content.index.created))
  }
  
  var isHiddenItem: Binding<Bool> {
    .constant(content.index.visibility == .hidden)
  }
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ResultThumbnail
      ResultDetails
    }
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
      ItemNameButton
        .buttonStyle(.weblink)
      
      ItemFolderButton
        .buttonStyle(.weblink)
      
      ResultItemTags
    }
  }
  
  var ResultItemCreatedOnTag: some View {
    TagButton(for: createdOnTag) {
      TagButtonConfiguration(
        menu: .tagMenu(when: .refiningSearchQuery),
        onMenuItem: onTagMenuItem,
      )
    }
  }

  var ResultItemTags: some View {
    HorizontalFlowView(vAlign: .firstTextBaseline, itemSpacing: 3, rowSpacing: 8) {
      ResultItemCreatedOnTag
      
      ForEach(tags, id: \.id) { tag in
        TagButton(for: tag) {
          TagButtonConfiguration(
            menu: .tagMenu(when: .refiningSearchQuery),
            onMenuItem: onTagMenuItem,
            onTap: onTagTap
          )
        }
      }
      
      Text(verbatim: "and \(tags.count - TAG_LIMIT) more...")
        .font(.caption)
        .visible(tags.count - TAG_LIMIT > 0)
    }
  }
  
  private var itemJSON: some Encodable {
    content.asSearchableItem(in: "<none>")
  }
  
  var ResultsInfoOverlay: some View {
    ThumbnailOverlayView(icon: .info, iconFont: .system(size: 16))
      .padding(8)
      .contentShape(Rectangle())
      .onTapGesture {
        showMetadataSheet.toggle()
      }
      .sheetView(isPresented: $showMetadataSheet, style: JsonSheetView.presentation) {
        JsonSheetView(
          object: .constant(itemJSON),
          onCopy: {
            dispatch(.copyToClipboard(value: $0))
          }
        )
      }
  }
  
  var ItemNameButton: some View {
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
  
  var ItemFolderButton: some View {
    NavigateToFolderButton(
      location: content.location,
      onTap: {
        dispatch(.showSheet(.none))
        navigate(.folder(content.location))
      }
    )
  }
}
