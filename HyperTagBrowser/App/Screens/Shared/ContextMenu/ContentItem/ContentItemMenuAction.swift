// created on 2/20/25 by robinsr

import Foundation


/**
 * Defines the actions that can be initiated from the context menu of either a single \
 * ContentItem or multiple ContentItems
 *
 * Depending on the situation/context, any number of `ContentItemMenuAction` items might
 * be available, while others will be logically excluded
 */
enum ContentItemMenuAction: MenuActionable {
  case showDetails
  case goToFolder
  case openInFinder
  case copyPath
  
  case createBookmark
  
    /// Remove item/s from the database
  case forgetItem
    /// Currently not implemented
  case resyncItem
    /// Pushes fresh search attributes for this item/s to the Spotlight index
  case reindexWithSpotlight
  
  case editTags
  case addTag(tag: FilteringTag)
  case applyTagStash(TagStash.ID)
  
  case filterOn(tag: FilteringTag)
  case filterOnMenu(label: String, tags: [FilteringTag])
  
  case relocate
  case rename
  case changeVisibility(ContentItemVisibility, count: Int = 1)
  case updateThumbnail(count: Int = 1)
  
  case addToQueueMenu
  case addToQueue(QueueRecord)
  
    /// Adds a separator
  case separator
  
    /// A no-op action when no action is required
  case noop
  
    /// Adds a non-clickable section header to the context menu
  case text(_ value: String, symbol: String = "")
  
  var id: String {
    .randomIdentifier(12)
  }
  
  var isNoop: Bool {
    switch self {
    case .noop: return true
    default: return false
    }
  }
  
  var nonFunctional: Bool {
    switch self {
    case .separator, .noop, .text(_, _): return true
    default: return false
    }
  }
  
  var isSubmenuParent: Bool {
    switch self {
    case .filterOnMenu(_,_), .addToQueueMenu: return true
    default: return false
    }
  }
  
  var supportsMultipleSelection: Bool {
    if nonFunctional {
      // Non-functional items like separators and headers don't result any actions
      return true
    }
    
    switch self {
      case
      
        // Can move multiple items at once
        .relocate,
        
        // Change visibility can be applied to multiple items if all items have the same initial visibility
        .changeVisibility( _, _),
        
        // These operate on a list of input IDs, one or more
        .updateThumbnail(_),
        .resyncItem,
        .forgetItem,
      
        // Tagging actions all support multiple selection
        .editTags,
        .addTag(_),
        .applyTagStash(_):
      return true
    default:
      return false
    }
  }
  
  var icon: String? {
    switch self {
    case .showDetails: SymbolIcon.info.systemName
    case .goToFolder: SymbolIcon.folder.systemName
    case .openInFinder: "questionmark.folder"
    case .createBookmark: SymbolIcon.bookmark.systemName
    case .forgetItem: "x.circle.fill"
    case .resyncItem: "arrow.clockwise.circle"
    case .reindexWithSpotlight: SymbolIcon.search.systemName
    case .editTags: SymbolIcon.tag.systemName
    case .addTag(let tag): tag.icon.systemName
    case .applyTagStash(_): SymbolIcon.insertText.systemName
    case .filterOn(let tag): tag.icon.systemName
    case .filterOnMenu(_,_): SymbolIcon.filterOn.systemName
    case .relocate: SymbolIcon.folder.systemName
    case .rename: SymbolIcon.editText.systemName
    case .changeVisibility(_, _): SymbolIcon.eyeslash.systemName
    case .updateThumbnail(_): SymbolIcon.camera.systemName
    case .addToQueueMenu: SymbolIcon.queue.systemName
    case .text(_, let symbol): symbol
    default: nil
    }
  }
  
  var label: String {
    switch self {
    
    case .text(let title, _): return title
      
    case .separator, .noop: return ""
      
    case .showDetails: return "Item Details"
    
    case .goToFolder: return "Open Containing Folder"
    
    case .openInFinder: return "Open in Finder"
      
    case .copyPath: return "Copy Pathname"
    
    case .createBookmark: return "Create Bookmark"
    
    case .forgetItem: return "Forget Item"
    
    case .resyncItem: return "Resync Item"
      
    case .reindexWithSpotlight: return "Reindex with Spotlight"
    
    case .editTags: return "Edit Tags"
      
    case .relocate: return "Relocate"
    
    case .rename: return "Rename"
    
    case .addToQueueMenu: return "Add to Queue"
    
    case .filterOnMenu(let label,_): return label
      
    case .filterOn(let tag):
      return "Filter on \(tag.value)"

    case .addTag(let tag):
      return "\(tag.value)"
    
    case .applyTagStash(let stashId):
      return "Apply Tag Stash \(stashId.id)"

    case .changeVisibility(let visibility,_):
      return visibilityIntentLabel(for: visibility)
    
    case .addToQueue(let queue):
      return "Add to Queue \(queue.name)"
      
    case .updateThumbnail(_):
      return "Update \("Thumbnail", qty: itemCount)"
    }
  }
  
  var itemCount: Int {
    switch self {
    case .changeVisibility(_, let count): count
    case .updateThumbnail(let count): count
    default: 1
    }
  }
  
  func visibilityIntentLabel(for vis: ContentItemVisibility) -> String {
    switch vis {
    case .normal: return "Unhide \("Items", qty: itemCount)"
    case .hidden: return "Hide \("Items", qty: itemCount)"
    default: return ""
    }
    
  }
}
