// created on 11/13/24 by robinsr

import Factory
import GRDBQuery
import SwiftUI


struct MultiSelectContextMenu: View {
  
  private let logger = EnvContainer.shared.logger("MultiSelectContextMenu")
  
  typealias Actions = ContentItemMenuAction
  
  @Environment(AppViewModel.self) var appVM
  @Environment(\.cursorState) var cursorState
  
  
  var onSelection: DispatchFn = { action in
    Container.shared.dispatcher().dispatch(action)
  }
  
  var contentItems: [ContentItem] {
    cursorState.selection
  }
  
  var itemCount: Int {
    contentItems.count
  }
  
  var hiddenItems: [ContentItem] {
    contentItems.visibility(eq: .hidden)
  }
  
  var visibleItems: [ContentItem] {
    contentItems.visibility(eq: .normal)
  }
  
  var menuActions: [ContentItemMenuAction] {
    let items: [ContentItemMenuAction?] = [
      .editTags,
      .relocate,
      .addToQueueMenu,
      hiddenItems.isEmpty ? nil : .changeVisibility(.hidden, count: itemCount),
      visibleItems.isEmpty ? nil : .changeVisibility(.normal, count: itemCount),
      .separator,
      .updateThumbnail(count: itemCount),
      .resyncItem,
      .reindexWithSpotlight,
      .separator,
      .forgetItem,
    ]
  
    return items.compactMap { $0 }
  }
  
  func modelAction(forSelected menuAction: ContentItemMenuAction) -> ModelActions {
    let itemScope: ContentScope = .include(contentItems.ids)
    
    switch menuAction {
      
    case .forgetItem:
      return .removeIndex(of: contentItems.pointers)
    
    case .resyncItem:
      return .notify(.init("Not implemented yet"))
      
    case .reindexWithSpotlight:
      return .updateSearchIndex(with: contentItems.pointers)
    
    case .editTags:
      return .editTags(of: contentItems.pointers)
    
    case .addTag(let tag):
      return .associateTag(tag, to: itemScope)
    
    case .applyTagStash(let stashId):
      return .associateTags(appVM.tagsStashed(in: stashId), to: itemScope)
    
    case .filterOn(let tag):
      return .addFilter(tag, .inclusive)
    
    case .relocate:
      return .showSheet(.chooseDirectory(for: contentItems.pointers))
    
    case .changeVisibility(let vis, _):
      if case .hidden = vis, !visibleItems.isEmpty {
        return .applyIndexPatch(.visibility(of: visibleItems.ids, with: vis))
      }
      
      if case .normal = vis, !hiddenItems.isEmpty {
        return .applyIndexPatch(.visibility(of: hiddenItems.ids, with: vis))
      }
      
      return .noop

    case .updateThumbnail(_):
      return .updateThumbnails(of: contentItems.records)
    
    case .addToQueue(let queue):
      return .enqueueItems(contentItems.pointers, into: queue.asFilter)
    
      // ContentItemMenuAction actions that are either non-functional or submenu groups
    default:
      if menuAction.nonFunctional { return .noop }
      if menuAction.isSubmenuParent { return .noop }
      
      if !menuAction.supportsMultipleSelection {
        logger.emit(.warning, "Disallowed action configured for MultiSelectContextMenu: \(menuAction.id)")
        return .noop
      }
      
      fatalError("Misconfiguration: \(menuAction) is not handled in MultiSelectContextMenu")
    }
  }
  
  
  
  private func handleButtonTap(_ action: Actions) {
    guard cursorState.manySelected else { return }
    
    onSelection(modelAction(forSelected: action))
  }
  
  
  var body: some View {
    ContextMenuTextItem("\("Content Item", qty: itemCount)")
    
    ForEach(menuActions, id: \.id) { action in
      if case .text(let value, let symbol) = action {
        ContextMenuTextItem(value, symbol)
      }
      
      else if case .separator = action {
        Divider()
          .id(String.randomIdentifier(12))
      }
      
      else if case .addToQueueMenu = action {
        AddToQueueMenu(items: contentItems, onSelection: onSelection)
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
