// created on 2/2/25 by robinsr


/**
 Defines the actions that can be performed for a given `FilteringTag`. Used to build the context menu for the tag.
 */
enum TagMenuAction: MenuActionable, Equatable, Hashable {
  
    /// Copy tag name
  case copyText
  
    /// Add "X" to filters
  case filterIncluding
  
    /// Add "not X" to filters
  case filterExcluding
  
    /// Remove "X" from filters
  case filterOff
  
    /// Toggle inclusive/exclusive setting for "X"
  case invert
    
    /// Remove "X" from current item
  case removeFrom(ContentId)
  
    /// Rename all/selected occurrences of "X"
  case renameAll
  
    /// Remove all/selected occurrences of "X"
  case removeAll
  
    /// Re-categorize a tag (eg from "artist" to "creator")
  case relabel(TagMenuContext)
  
    /// Search for "X"
  case searchFor
  
    /// Change Date
  case changeDate
  
    /// Adds a separator
  case separator
  
    /// Adds a non-clickable section header to the context menu
  case text(_ value: String, symbol: String = "")
  
    /// A no-op option to indicate no action should be performed
  case noop
  
  
  /**
   * Returns a noop `TagMenuAction` to serve as a label for a section within a context menu.
   */
  static func label(for section: TagMenuSection) -> TagMenuAction {
    section.title ?? .text("")
  }
  
  
  var id: String {
    switch self {
    case .copyText: return "copyText"
    case .filterIncluding: return "filterIncluding"
    case .filterExcluding: return "filterExcluding"
    case .filterOff: return "filterOff"
    case .invert: return "invert"
    case .removeFrom: return "removeFrom"
    case .renameAll: return "renameAll"
    case .removeAll: return "removeAll"
    case .relabel: return "relabel"
    case .searchFor: return "searchFor"
    case .changeDate: return "changeDate"
    case .text(_,_): return "text"
    case .separator: return "separator"
    case .noop: return ""
    }
  }
  
  /**
   Name of the symbol to use for UI elements
   */
  var icon: String? {
    switch self {
    case .copyText: return "doc.on.doc"
    case .filterIncluding: return "tag.fill"
    case .filterExcluding: return "tag.slash"
    case .filterOff: return "minus.rectangle"
    case .invert: return "arrow.up.arrow.down"
    case .removeFrom: return "tag.slash"
    case .renameAll: return "rectangle.and.pencil.and.ellipsis"
    case .removeAll: return "xmark"
    case .relabel: return "books.vertical"
    case .searchFor: return "magnifyingglass"
    case .changeDate: return "calendar"
    case .text(_, let symbol): return symbol
    default: return nil
    }
  }
  
  
  /**
   The display string for the button
   */
  var label: String {
    switch self {
    case .copyText: return "Copy Tag Value"
    case .filterIncluding: return "Filter Like This"
    case .filterExcluding: return "Filter Not Like This"
    case .filterOff: return "Remove from Filters"
    case .invert: return "Invert Filtering"
    case .removeFrom: return "Untag Item"
    case .renameAll: return "Rename Occurrences"
    case .removeAll: return "Remove Occurrences"
    case .relabel(let context):
      switch context {
      case .taggedOn(_): return "Recatagorize Tag"
      default: return "Change Filter Type"
      }
    case .searchFor: return "Search Tag Value"
    case .changeDate: return "Update Date Value"
    case .separator: return ""
    case .text(let title, _): return title
    case .noop: return ""
    }
  }
}
