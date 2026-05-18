// created on 9/15/24 by robinsr

import Foundation
import SwiftUI
import Regex


/**
 * Provides a reusable and reference-able container for a keyboard shortcut (a primary key and its modifiers),
 *
 * This is used to centralize the management of keyboard shortcuts within the application
 */
//struct KeyBinding: RawRepresentable, Identifiable, Hashable, Equatable, Sendable {
struct KeyBinding: Identifiable, Hashable, Equatable, Sendable {
  var name: String
  var keyboardShortcut: KeyboardShortcut
  let id: String = .randomIdentifier(20)
  
  init(_ key: KeyEquivalent, _ mods: EventModifiers) {
    self.keyboardShortcut = KeyboardShortcut(key, modifiers: mods)
    self.name = "Unnamed [\(keyboardShortcut.description)]"
  }
  
  init(_ key: KeyEquivalent, _ mods: EventModifiers, named name: String) {
    self.keyboardShortcut = KeyboardShortcut(key, modifiers: mods)
    self.name = name
  }
  
  init(_ expression: String, named name: String) {
    guard let char = expression.last
            //, (char.isLetter || char.isNumber || char.isSymbol)
    else {
      fatalError("Invalid shortcut pattern: \(expression)")
    }
    
    let key = KeyEquivalent(char)
    let mods = EventModifiers(string: expression)
    
    self.init(key, mods, named: name)
  }
  
  var shortcut: KeyboardShortcut {
    keyboardShortcut
  }
  
  var mods: EventModifiers {
    keyboardShortcut.modifiers
  }
  
  var key: KeyEquivalent {
    keyboardShortcut.key
  }
  
  func duplicate(_ name: String) -> KeyBinding {
    return .init(key, mods, named: name)
  }
  
  /**
   * Duplicates the KeyBinding, adding an additional modifier key
   */
  func plus(_ other: EventModifiers, named name: String? = nil) -> KeyBinding {
    .init(key, mods.union(other), named: name ?? self.name)
  }
  
  static func == (lhs: KeyBinding, rhs: KeyBinding) -> Bool {
    let keyEq = lhs.key == rhs.key
    let modEq = lhs.mods == rhs.mods
    
    return keyEq && modEq
  }
  
  var symbols: String {
    keyboardShortcut.modifiers.asSymbols.joined() + key.asSymbol
  }
  
  @available(*, deprecated, renamed: "symbols", message: "Use symbols instead.")
  var asCharacters: String {
    self.symbols
  }
  
  @available(*, deprecated, renamed: "symbols", message: "Use symbols instead.")
  var string: String {
    self.symbols
  }
}


extension KeyBinding: CustomStringConvertible {
  var description: String {
    "[\(self.symbols)]"
  }
}

extension KeyBinding: CustomDebugStringConvertible {
  var debugDescription: String {
    "KeyBinding(name=\(name), shortcut=\(describing: keyboardShortcut))"
  }
}


extension KeyBinding {

  static let gridCursorRight    = KeyBinding(.rightArrow, [])
  static let gridCursorLeft     = KeyBinding(.leftArrow, [])
  static let gridCursorDown     = KeyBinding(.downArrow, [])
  static let gridCursorUp       = KeyBinding(.upArrow, [])
  static let gridSelect         = KeyBinding(.space, [])
  static let listEditorDown     = KeyBinding(.downArrow, [])
  static let listEditorUp       = KeyBinding(.upArrow, [])
  static let onEnter            = KeyBinding(.return, [])

  
  static let hzNextItem            = KeyBinding("⌃.", named: "Next Suggestion")
  static let hzPrevItem            = KeyBinding("⌃,", named: "Previous Suggestion")
  
  static let listEditorLeft        = KeyBinding("⌘[", named: "Previous Suggestion (alt)")
  static let listEditorRight       = KeyBinding("⌘]", named: "Next Suggestion (alt)")
  
  static let showPreferences       = KeyBinding("⌘,", named: "Show preferences")
  static let help                  = KeyBinding("⇧⌘?", named: "Show help window")
  static let dismiss               = KeyBinding(.escape, [], named: "Close Current View")
  
  static let openDir               = AppSheet.Cases.changeDirectory.shortcut
  static let forward               = KeyBinding("⇧⌘]", named: "Go Forward (alt)")
  static let goBack                = KeyBinding("⇧⌘[", named: "Go Back (alt)")
  static let goForward             = KeyBinding("⌘→", named: "Go Forward")
  static let back                  = KeyBinding("⌘←", named: "Go Back")
  static let navDirUp              = KeyBinding("⌘↑", named: "Go Up One Folder")
  static let reload                = KeyBinding("⇧⌘R", named: "Refresh Query")
  
  static let showQuickActions      = AppPanels.quickActions.shortcut
  static let toggleSidebar         = AppPanels.sidebar.shortcut
  static let toggleSidebarSide     = KeyBinding("⇧⌃S", named: "Toggle Sidebar Position")
  static let toggleManageTags      = AppPanels.tagmanager.shortcut
  static let toggleFilters         = AppPanels.browseRefinements.shortcut
  static let toggleBookmarks       = AppPanels.bookmarks.shortcut
  static let toggleQueueList       = AppPanels.workqueues.shortcut
  
  static let showSearch            = KeyBinding("⌘F", named: "Search")
  static let showProfiles          = AppSheet.Cases.userProfiles.shortcut
  
  static let copy                  = KeyBinding("⌘C", named: "Copy")
  static let paste                 = KeyBinding("⌘V", named: "Paste")
  static let info                  = AppSheet.Cases.contentDetailSheet.shortcut
  static let editTags              = AppSheet.Cases.editItemTagsSheet.shortcut
  static let renameItem            = AppSheet.Cases.renameContentSheet.shortcut
  static let relocateSelection     = AppSheet.Cases.chooseDirectory.shortcut
  static let selectAll             = KeyBinding("⌘A", named: "Select All")
  
  static let browseGridMode        = KeyBinding("⇧⌘1", named: "Show Items in Grid")
  static let browseTableMode       = KeyBinding("⇧⌘2", named: "Show Items in Table")
  static let decreaseTileSize      = KeyBinding("⌘-", named: "Zoom Out / Decrease Tile Size")
  static let increaseTileSize      = KeyBinding("⌘+", named: "Zoom In / Increase Tile Size")
  static let zoomActual            = KeyBinding("⌘0", named: "Actual Size")
  static let zoomFitted            = KeyBinding("⌘9", named: "Zoom to Fit")
  static let toggleFillMode        = KeyBinding("M", named: "Toggle Fill Mode")
  
  
  static let toggleListMode        = KeyBinding("⌘L", named: "Toggle List Mode")
  static let toggleMatchOperator   = KeyBinding("⇧⌘L", named: "Toggle Filtering Operator")
  static let cycleSortMode         = KeyBinding("⇧⌘s", named: "Cycle Sort Mode")
  static let toggleVisibility      = KeyBinding("⇧⌘V", named: "Toggle Visibility")
  static let clearFilters          = KeyBinding("⌘X", named: "Clear Current Filters")
  
  static let newQueue              = KeyBinding("⌘N", named: "New Queue")
  static let startIndexer          = KeyBinding("⌘⇧I", named: "Re-Index Current Location")
  
  
  static func indexed(_ index: Int, _ mods: EventModifiers = []) -> KeyBinding {
    KeyBinding(KeyEquivalent.numeric[safe: index % 10]!, mods)
  }
  
  static func numShortcut(_ index: Int, _ mods: EventModifiers = []) -> KeyBinding {
    // This is a convenience method to get the numeric shortcut by index
    indexed(index, mods)
  }
  
  static var cmdIndexed: [KeyBinding] {
    KeyEquivalent.numeric.map { KeyBinding($0, [.command]) }
  }
  
  static var ctrlIndexed: [KeyBinding] {
    KeyEquivalent.numeric.map { KeyBinding($0, [.control]) }
  }
}
