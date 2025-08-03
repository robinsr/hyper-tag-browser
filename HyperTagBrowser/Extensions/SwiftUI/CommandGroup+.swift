// created on 5/28/25 by robinsr

import SwiftUI


/**
 * Defines well-known top-level menu bar groups (File, Edit, View, etc.)
 */
enum MenuBarGroup: String {
  case application
  case file
  case edit
  case view
  case window
  case help
  
  /**
   * Returns a set of `CommandGroupPlacement` values that correspond to this menu group.
   */
  var placements: [CommandGroupPlacement] {
    switch self {
    case .application:
      return [.appInfo, .appSettings, .appVisibility, .appTermination, .importExport, .pasteboard, .systemServices]
    case .file:
      return [.newItem, .saveItem, .printItem]
    case .edit:
      return [.textEditing, .textFormatting, .undoRedo]
    case .view:
      return [.toolbar, .sidebar]
    case .window:
      return [.windowArrangement, .windowList, .windowSize, .singleWindowList]
    case .help:
      return [.help]
    }
  }
}


extension CommandGroup where Content : View  {
  /**
   * Creates a `CommandGroup` placed before the specified `MenuBarGroup`.
   */
  init(before group: MenuBarGroup, @ViewBuilder addition: () -> Content) {
    self.init(before: group.placements.first!, addition: addition)
  }
  
  /**
   * Creates a `CommandGroup` placed after the specified `MenuBarGroup`.
   */
  init(after group: MenuBarGroup, @ViewBuilder addition: () -> Content) {
    self.init(after: group.placements.first!, addition: addition)
  }
}

