// created on 2/10/25 by robinsr

import SwiftUI


enum AppPanels: String, Identifiable, Hashable {
  case quickActions
  case sidebar
  case browseRefinements
  case bookmarks
  case workqueues
  case tagmanager
  
  var id: String {
    self.rawValue
  }
  
  var parent: AppPanels? {
    switch self {
    case .bookmarks, .workqueues, .tagmanager:
      return .sidebar
    default:
      return nil
    }
  }
  
  var title: String {
    switch self {
    case .quickActions:
      return "Quick Actions"
    case .sidebar:
      return "Sidebar"
    case .browseRefinements:
      return "Browse Refinements"
    case .bookmarks:
      return "Bookmarks"
    case .workqueues:
      return "Work Queues"
    case .tagmanager:
      return "Tag Manager"
    }
  }
  
  var keys: String {
    switch self {
    case .quickActions:
      return "⇧⌘P"
    case .sidebar:
      return "⌃S"
    case .browseRefinements:
      return "⌃F"
    case .bookmarks:
      return "⌃B"
    case .workqueues:
      return "⌃Q"
    case .tagmanager:
      return "⌃T"
    }
  }
  
  func shortcut(isShowing: Bool = false) -> KeyBinding {
    KeyBinding(keys, named: "\(isShowing ? "Hide" : "Show") \(title)")
  }
  
  var shortcut: KeyBinding {
    switch self {
    case .quickActions:
      KeyBinding("⇧⌘P", named: "Show Quick Actions")
    case .sidebar:
      KeyBinding("⌃S", named: "Toggle Sidebar")
    case .browseRefinements:
      KeyBinding("⌃F", named: "Show Filters")
    case .bookmarks:
      KeyBinding("⌃B", named: "Show Bookmarks")
    case .workqueues:
      KeyBinding("⌃Q", named: "Show Work Queues")
    case .tagmanager:
      KeyBinding("⌃T", named: "Manage Tags")
    }
  }
  
  /**
   * Defines the order in which panels should be closed when the user presses the close button.
   */
  static var closePriority: [AppPanels] {
    [.quickActions, .bookmarks, .workqueues, .tagmanager, .sidebar, .browseRefinements]
  }
}
