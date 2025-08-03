// created on 5/28/25 by robinsr

import Factory



/**
 * Centralized store of dispatch functions. Functions of `CommandExecutor`
 * can be invoked from various UI components. A non exhaustive list incudes
 *
 * - toolbar buttons
 * - context menus
 * - app menus
 * - K-bar / "command bar" / "command palette"
 *
 * Just a DRY way to handle commands in a centralized way.
 */
struct CommandExecutor {
  
  @Injected(\Container.appViewModel) var appVM
  @Injected(\Container.detailViewModel) var detailEnv
  @Injected(\Container.thumbnailStore) var thumbnailStore
  @Injected(\Container.cursorState) var cursor
  
  
  /// Proxy to the app's dispatch function
  private var dispatch: DispatchFn {
    appVM.dispatch
  }
  
  /// Proxy to the app's navigation function
  private var navigate: PushNavigationFn {
    appVM.navigate
  }
  
    // MARK: - Menu Items
  
  func dev_testDispatchQueueButton() {
    dispatch(.testDispatchQueues)
  }
  
  func toggleSheetAction(_ sheet: AppSheet) -> (() -> Void) {
    return {
      appVM.dispatch(.showSheet(sheet))
    }
  }
  
  func dev_clearThumbnailCacheButton() {
    do {
      try thumbnailStore.clear()
      dispatch(.notify(.ok("Thumbnail cache cleared successfully.")))
    } catch {
        // TODO: This is verbose
      dispatch(.notify(.error(.modeled(.clearThumbnailCache(error)))))
    }
  }
  
  
    // MARK: - File Menu Items
  
  func file_IndexLocationButton() {
    dispatch(.indexItems(inFolder: appVM.location))
  }
  
  func file_BackupDatabaseButton() {
    dispatch(.backupDatabase)
  }
  
    // MARK: - Navigate Menu Items
  
  func navigate_BackButton() {
    dispatch(.popRoute)
  }

  func navigate_UpDirButton() {
    navigate(.folder(appVM.location.filepath.directory))
  }

  func navigate_HomeButton() {
    dispatch(.showSheet(.none))
    navigate(.main)
  }
  
  
    // MARK: - Query Menu Items
  
  func query_ReloadQueryButton() {
    dispatch(.reloadQuery)
  }

  func query_ToggleListModeButton() {
    dispatch(.toggleListMode)
  }

  func query_ClearFiltersButton() {
    dispatch(.clearFilters)
  }

  func query_ToggleOperatorButton() {
    dispatch(.toggleFilterOperator)
  }
  
  
  // MARK: - Edit Menu Items
  
  var route: Route {
    appVM.currentRoute
  }
  
  func edit_EditTagsButton() {
    if !appVM.editableContent.isEmpty {
      dispatch(.editTags(of: appVM.editableContent.pointers))
    }
  }
  
  func edit_RenameItemButton() {
    guard appVM.editableContent.count == 1 else { return }
    guard let contentItem = appVM.editableContent.first else { return }
    
    dispatch(.editName(of: contentItem.pointer))
  }
  
  func edit_MoveItemButton() {
    if !appVM.editableContent.isEmpty {
      dispatch(.showSheet(.chooseDirectory(for: appVM.editableContent.pointers)))
    }
  }
  
  func edit_SelectAllItemsButton() {
    if route.page.oneOf(.main, .folder) {
      cursor.selectAll()
    }
  }
  
  
}
