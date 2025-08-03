// created on 4/23/25 by robinsr


/**
 * List Editor Actions
 */
enum ListEditorActions: String {
  /// Appends a new item to the list
  case append = "Add new tag"
  /// Prependd a new item to the list
  case prepend = "Add new tag (to front)"
  /// Replace the currently focused item with new value
  case replace = "Replace this tag"
  /// Insert a new item within the item list, or overwrite the value of a current item
  case insert = "Add new tag before this tag"
  /// Toggle value of `selected` on currently highlighted item
  case toggle = "Toggle this tag"
  /// Adds a string of all items to copy into another list editor to the system clipboard
  case copy = "Copy tags"
  /// Fetches the system clipboard and applies the list items found therein
  case paste = "Paste tags"
  /// Done command, calls the completion closures with new set of list values
  case done = "Done"
  
  case filterOn = "Filter on this tag"
  
  
  /// No action is currently possible
  case none = "..."

  /// Returns a SF Icon string for the command type
  var icon: SymbolIcon {
    switch self {
    case .append: return .editText
    case .prepend: return .editText
    case .toggle: return .itemChecked
    case .replace: return .insertText
    case .insert: return .insertText
    case .copy: return .copy
    case .paste: return .paste
    case .done: return .lgtm
    case .filterOn: return .filterOn
    
    case .none: return .unknown
    }
  }
}
