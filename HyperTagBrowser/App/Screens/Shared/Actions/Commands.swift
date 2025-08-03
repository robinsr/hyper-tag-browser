// created on 9/26/24 by robinsr

import GRDBQuery
import Defaults
import Factory
import SwiftUI



struct CommandsView: Commands {
  @FocusedValue(\.focusedViewModel) var appVM: AppViewModel?
  @FocusedValue(\.activeAppSheet) var activeSheet
  
  @Environment(\.cursorState) var cursor
  @Environment(\.detailEnv) var detailEnv
  @Environment(\.openWindow) var openWindow
  
  @Default(.gridTileSize) var tileSize
  
  @Injected(\Container.executor) var exec
  @Injected(\Container.thumbnailStore) var thumbnailStore
  
  @Query(ListSavedQueriesRequest()) var savedQueries
  
  
  var currentPointer: ContentPointer? {
    appVM?.detailItemPointer
  }
  
  var selectedItems: [ContentPointer] {
    cursor.selection.map(\.pointer)
  }
  
  var body: some Commands {
    // File Menu
    AppFileManu
    
    // Edit Menu
    AppEditMenu
    
    // View Menu
    AppViewMenu
    
    // Navigate Menu
    NavigateMenu
    
    // Query Menu
    QueryMenu
    
    // Help Menu
    AppHelpMenu
  }

  var AppFileManu: some Commands {
    CommandGroup(before: .newItem) {
      File_IndexLocationButton
      
      Divider()
      
      File_BackupDatabaseButton
      
      Divider()
      
      File_CreateQueueButton
      File_ShowSearchButton
    }
  }
  
  var AppEditMenu: some Commands {
    CommandGroup(before: .textEditing) {
      Edit_EditTagsButton
      Edit_RenameItemButton
      Edit_MoveItemButton
      Edit_SelectAllItemsButton
    }
  }
  
  var AppViewMenu: some Commands {
    CommandGroup(before: .view) {
      
      View_UIPanelButtons
      
      Divider()
      
      View_ToggleSidebarPositionButton
      
      Divider()
      
      View_IncreaseTileSizeButton
      View_DecreaseTileSizeButton
      
      Divider()
      
      View_ToggleFillModeButton
    }
  }
  
  var NavigateMenu: some Commands {
    CommandMenu("Navigate") {
      
      Navigate_BackButton
      Navigate_UpDirButton
      Navigate_HomeButton
      Navigate_OpenDirectoryButton
    }
  }
  
  var QueryMenu: some Commands {
    CommandMenu("Query") {
      
      Query_ReloadQueryButton
      Query_ToggleListModeButton
      Query_ToggleOperatorButton
      
      Divider()
      
      Query_ClearFiltersButton
      
      Divider()
      
      Query_SortByMenu
      
      Divider()
      
      Query_SavedQueriesMenu
    }
  }
  
  var AppHelpMenu: some Commands {
    CommandGroup(replacing: .help) {
      ShowHelpButton
      
      Divider()
      
      #if DEBUG
      Debug_AdvancedMenu
      #endif
    }
  }
  
  var Debug_AdvancedMenu: some View {
    Menu("Advanced") {
      TestDispatchQueueButton
      ClearThumbnailCacheButton
    }
  }
  
  /// Proxy to the app's dispatch function.
  func dispatch(_ action: ModelActions) {
    if let vm = appVM {
      vm.dispatch(action)
    }
  }
  
  
    // MARK: - Menu Items
  
  var TestDispatchQueueButton: some View {
    Button("Test Dispatch Queue", action: exec.dev_testDispatchQueueButton)
  }
  
  var ClearThumbnailCacheButton: some View {
    Button("Clear Thumbnail Cache", action: exec.dev_clearThumbnailCacheButton)
  }
  

  
  func KeyBindingButton(
    _ kb: KeyBinding,
    disablers: Set<KeyBinding.DisableWhen> = [],
    action: @escaping () -> Void
  ) -> some View {
    var buttonDisabled: Bool = FirstTrueBuilder.withDefault(false) {
      (appVM == nil, false)
      (disablers.isEmpty, false)
      (disablers.contains(.anySheet) && activeSheet != AppSheet.none, true)
      (disablers.contains(sheet: activeSheet), true)
    }
    
    return
      Button(kb.description, action: action)
        .keyboardShortcut(kb)
        .disabled(buttonDisabled)
  }
  
  func SheetBindingButton(_ sheet: AppSheet) -> some View {
    let isShowing = activeSheet == sheet
    let shortcut = sheet._case.shortcut(isShowing: isShowing)
    
    return Button(shortcut.description, action: exec.toggleSheetAction(sheet))
      .keyboardShortcut(shortcut)
  }
  
    // MARK: - File Menu Items
  
  var File_IndexLocationButton: some View {
    KeyBindingButton(.startIndexer, action: exec.file_IndexLocationButton)
  }

  var File_BackupDatabaseButton: some View {
    Button("Backup dataabse", action: exec.file_BackupDatabaseButton)
  }
  
  var File_CreateQueueButton: some View {
    SheetBindingButton(.createQueueSheet)
  }
  
  var File_ShowSearchButton: some View {
    SheetBindingButton(.searchSheet(query: ""))
  }
  
    // MARK: - Navigate Menu Items
  
  var Navigate_BackButton: some View {
    KeyBindingButton(.back, disablers: [.anySheet], action: exec.navigate_BackButton)
  }
  
  var Navigate_UpDirButton: some View {
    KeyBindingButton(.navDirUp, disablers: [.anySheet], action: exec.navigate_UpDirButton)
  }
  
  var Navigate_HomeButton: some View {
    Button("Home", action: exec.navigate_HomeButton)
  }
  
  var Navigate_OpenDirectoryButton: some View {
    SheetBindingButton(.changeDirectory)
  }
  
  
    // MARK: - Query Menu Items
  
  var Query_ReloadQueryButton: some View {
    KeyBindingButton(.reload, action: exec.query_ReloadQueryButton)
  }

  var Query_ToggleListModeButton: some View {
    KeyBindingButton(.toggleListMode, action: exec.query_ToggleListModeButton)
  }

  var Query_ClearFiltersButton: some View {
    KeyBindingButton(.clearFilters, action: exec.query_ClearFiltersButton)
  }

  var Query_ToggleOperatorButton: some View {
    KeyBindingButton(.toggleMatchOperator, action: exec.query_ToggleOperatorButton)
  }
  
  @ViewBuilder
  var Query_SortByMenu: some View {
    MenuSelect(
      selection: .constant(appVM?.dbIndexParameters.sortBy ?? .nameAsc),
      using: SortType.self,
      itemLabel: { _ in
          Text("Sort by")
      },
      onSelection: { val in
        dispatch(.setSortMode(val))
      })
    
    Divider()
    
    KeyBindingButton(.cycleSortMode) {
      dispatch(.cycleSortMode)
    }
  }
  
  var Query_SavedQueriesMenu: some View {
    Menu("Saved Queries") {
      ForEach(savedQueries, id: \.id) { query in
        Button {
          dispatch(.applySavedQuery(query.id))
        } label: {
          Text(query.name)
          Text("Created \(query.createdAt.formatted(.short))")
        }
      }
      
      Divider()
      
      Query_ManageSavedQueriesButton
    }
  }
  
    // TODO: Launch a sheet to manage saved queries
  var Query_ManageSavedQueriesButton: some View {
    Button("Manage Saved Queries") {
      dispatch(.showSheet(.newSavedQuerySheet(query: BrowseFilters.defaults.contentItems)))
    }
  }
  
    // MARK: - View Menu Items
  
  @ViewBuilder
  var View_UIPanelButtons: some View {
    ActionMenuButton(command: TogglePanelAction(panel: .quickActions))
    ActionMenuButton(command: TogglePanelAction(panel: .quickActions))
    ActionMenuButton(command: TogglePanelAction(panel: .browseRefinements))
    ActionMenuButton(command: TogglePanelAction(panel: .sidebar))
    ActionMenuButton(command: TogglePanelAction(panel: .bookmarks))
    ActionMenuButton(command: TogglePanelAction(panel: .tagmanager))
    ActionMenuButton(command: ToggleSheetAction(sheet: .userProfiles))
  }
  
  var View_DecreaseTileSizeButton: some View {
    KeyBindingButton(.decreaseTileSize) {
      tileSize = Double.maximum(Constants.minTileSize, tileSize - 25.0)
    }
  }
  
  var View_IncreaseTileSizeButton: some View {
    KeyBindingButton(.increaseTileSize) {
      tileSize = Double.minimum(Constants.maxTileSize, tileSize + 25.0)
    }
  }
  
  var View_ToggleFillModeButton: some View {
    KeyBindingButton(.toggleFillMode) {
      detailEnv.toggleFillMode()
    }
  }
  
  var View_ToggleSidebarPositionButton: some View {
    Button {
      switch Defaults[.sidebarPosition] {
      case .left:
        Defaults[.sidebarPosition] = .right
      case .right:
        Defaults[.sidebarPosition] = .left
      }
    } label: {
      Text("Toggle Sidebar Position")
    }
    .keyboardShortcut(.toggleSidebarPosition)
  }

  
    // MARK: - View → Panels Menu Items

  var ShowHelpButton: some View {
    Button("\(Constants.appname) Help") {
      openWindow(id: HelpScreen.screenId)
    }
    .keyboardShortcut(.help)
  }
  
  
    // MARK: - Edit Item Menu Items

  var Edit_EditTagsButton: some View {
    Button("Edit Tags", action: exec.edit_EditTagsButton)
  }
  
  var Edit_RenameItemButton: some View {
    Button("Rename", action: exec.edit_RenameItemButton)
  }
  
  var Edit_MoveItemButton: some View {
    Button("Move to folder", action: exec.edit_MoveItemButton)
  }
  
  var Edit_SelectAllItemsButton: some View {
    Button("Select All", action: exec.edit_SelectAllItemsButton)
  }
}

