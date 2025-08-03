// created on 11/15/24 by robinsr

import Factory
import GRDBQuery
import SwiftUI


struct ContentItemContextMenu: View {
  
  private let logger = EnvContainer.shared.logger("MultiSelectContextMenu")
  
  @Environment(AppViewModel.self) var appVM
  
  @Query(ListQueuesRequest()) var queues: [QueueRecord]
  @Query(ListBookmarksRequest()) var bookmarks: [BookmarkItem]
  
  let contentItem: ContentItem
  let onSelection: DispatchFn
  
  var pointer: ContentPointer {
    contentItem.pointer
  }
  
  var itemScope: ContentScope {
    .one(contentItem.pointer)
  }
  
  var itemURL: URL {
    contentItem.url
  }
  
  var itemVisibility: ContentItemVisibility {
    contentItem.index.visibility
  }
  
  var itemCreated: Date {
    contentItem.index.created
  }
  
  var timeTags: [FilteringTag] {
    [
      .created(.init(date: itemCreated, bounds: .before)),
      .created(.init(date: itemCreated, bounds: .onOrBefore)),
      .created(.init(date: itemCreated, bounds: .on)),
      .created(.init(date: itemCreated, bounds: .onOrAfter)),
      .created(.init(date: itemCreated, bounds: .after)),
    ]
  }
  
  var menuActions: [ContentItemMenuAction] {
    
    let folderActions: [ContentItemMenuAction] = [
      .createBookmark,
      .separator,
      .rename,
      .relocate,
      .separator,
      .goToFolder
    ]
    
    let contentActions: [ContentItemMenuAction] = [
      .editTags,
      .filterOnMenu(label: "Filter on Tag", tags: contentItem.tags),
      .filterOnMenu(label: "Filter on Date Created", tags: timeTags),
      .separator,
      .rename,
      .relocate,
      .changeVisibility(itemVisibility.inverse, count: 1),
      .updateThumbnail(count: 1),
      .reindexWithSpotlight,
      .separator,
      .showDetails,
      .goToFolder,
    ]
    
    let commonActions: [ContentItemMenuAction] = [
      .openInFinder,
      .copyPath,
      .separator,
      .forgetItem,
    ]
    
    if contentItem.conforms(to: .folder) {
      return [folderActions + commonActions].flatMap { $0 }
    }
    
    if contentItem.conforms(to: .content) {
      return [contentActions + commonActions].flatMap { $0 }
    }
    
    return []
  }
  
  func modelAction(forSelected menuAction: ContentItemMenuAction) -> ModelActions {
    switch menuAction {
    
    case .addTag(let tag):
      return .associateTag(tag, to: itemScope)
    
    case .addToQueue(let queue):
      return .enqueueItems([pointer], into: queue.asFilter)
    
    case .applyTagStash(let stashId):
      return .associateTags(appVM.tagsStashed(in: stashId), to: itemScope)
    
    case .changeVisibility(let vis, _):
      return .updateIndex(.visibility(of: [contentItem.id], with: vis))
    
    case .copyPath:
      return .copyToClipboard(label: "", value: contentItem.url.filepath.string)
    
    case .createBookmark:
      return .bookmarkContent(contentItem)
    
    case .editTags:
      return .editTags(of: [pointer])
    
    case .filterOn(let tag):
      return .addFilter(tag, .inclusive)
    
    case .forgetItem:
      return .removeIndex(of: [pointer])
    
    case .goToFolder:
      return .navigate(to: .folder(contentItem.location), .push)
    
    case .openInFinder:
      return .revealItem(contentItem.url)
    
    case .reindexWithSpotlight:
      return .updateSearchIndex(with: [pointer])
    
    case .relocate:
      return .showSheet(.chooseDirectory(for: [pointer]))
      
    case .rename:
      return .showSheet(.renameContentSheet(item: contentItem))
    
    case .resyncItem:
      return .notify(.init("Not implemented yet"))
    
    case .showDetails:
      return .showSheet(.contentDetailSheet(item: contentItem))
    
    case .updateThumbnail(_):
      return .updateThumbnails(of: [contentItem.index])

       // No-op cases
    
    case .filterOnMenu(_,_):
      return .noop
    case .addToQueueMenu:
      return .noop
    case .separator:
      return .noop
    case .noop:
      return .noop
    case .text(_,_):
      return .noop
    }
  }
  
  
  
  private func handleButtonTap(_ action: ContentItemMenuAction) {
    onSelection(modelAction(forSelected: action))
  }
  
  
  var body: some View {
    ForEach(menuActions, id: \.id) { action in
      if case .text(let value, let symbol) = action {
        ContextMenuTextItem(value, symbol)
      }
      
      else if case .separator = action {
        Divider()
          .id(String.randomIdentifier(12))
      }
      
      else if case .addToQueueMenu = action {
        AddToQueueMenu(
          queues: queues,
          items: [contentItem],
          onSelection: onSelection
        )
      }
      
      else if case .filterOnMenu(let label, let tags) = action {
        FilterOnTagsMenu(
          label: label,
          tags: tags,
          onSelection: onSelection
        )
      }
      
      else {
        ContextMenuButton(action) {
          handleButtonTap(action)
        }
      }
    }
  }
}
