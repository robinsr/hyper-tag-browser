// created on 5/28/25 by robinsr

import Factory
import KBar
import SwiftUI



/**
 * A "command bar" style action dispatcher. Not sure if gonna use.
 */
struct QuickActionsView: View {
  @Environment(AppViewModel.self) var appVM
  
  @Injected(\Container.executor) var exec
  
  @Binding var isPresented: Bool
  
  @State var favoriteNumbers : [Int] = []

  var items: [KBar.Item] {
    let panels = [
      TogglePanelAction(panel: .quickActions),
      TogglePanelAction(panel: .bookmarks),
      TogglePanelAction(panel: .browseRefinements),
      TogglePanelAction(panel: .sidebar),
      TogglePanelAction(panel: .tagmanager),
      TogglePanelAction(panel: .workqueues),
    ]
    
    let sheets = [
      ToggleSheetAction(sheet: .userProfiles),
      ToggleSheetAction(sheet: .changeDirectory),
      ToggleSheetAction(sheet: .searchSheet(query: "")),
    ]
    
    let actions: [any ActionableCommand] = panels + sheets
    
    var kbaritems = actions.map { action in
      KBar.Item(title: action.title, callback: {
        action.perform(app: appVM)
      })
    }
    
    
    
    kbaritems.append(contentsOf: [
      KBar.Item(
        title: "Edit Tags of Selection",
        callback: exec.edit_EditTagsButton
      ),
      KBar.Item(
        title: "Rename Selection",
        callback: exec.edit_RenameItemButton
      ),
      KBar.Item(
        title: "Relocate Selection",
        subtitle: "move file or files to a new folder",
        callback: exec.edit_MoveItemButton
      ),
      KBar.Item(
        title: "Refresh",
        subtitle: "check for changes in the current folder",
        callback: exec.query_ReloadQueryButton
      ),
      KBar.Item(
        title: "Clear Filters",
        subtitle: "removes all filters",
        callback: exec.query_ClearFiltersButton
      ),
      KBar.Item(
        title: "Recursive Items",
        subtitle: "show all subcontents of the current folder",
        callback: { appVM.dispatch(.setListMode(.recursive(.cached))) }
      ),
      KBar.Item(
        title: "Folder Items",
        subtitle: "show contents of the current folder, excluding subfolders",
        callback: { appVM.dispatch(.setListMode(.immediate(.cached))) }
      ),
      KBar.Item(
        title: "Match All Filters",
        callback: { appVM.dispatch(.setFilterOperator(.and)) }
      ),
      KBar.Item(
        title: "Match Any Filters",
        callback: { appVM.dispatch(.setFilterOperator(.or)) }
      ),
    ])
    
    return kbaritems
  }

  var body : some View {
    ZStack {
      KBar(isActive: $isPresented, items: items)
        .onDisappear {
          
        }
    }
  }
}

/*
 public var defaultImage = "circle.fill"
 public var keybinding : KeyboardShortcut? = KeyboardShortcut("k")
 public var showImages = true
 public var maxItemsShown = 6
 public var veil : some View = Color.init(white: 0.1).opacity(0.85)
 public var defaultItems : [any KBarItem] = []
 public var placeholderText = "Search"
 
 public var additionalItemsForSearch : ((String) -> [any KBarItem])? = nil
 */
