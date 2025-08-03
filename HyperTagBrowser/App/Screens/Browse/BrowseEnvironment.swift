// created on 3/14/25 by robinsr

import CustomDump
import Defaults
import Factory
import GRDBQuery
import SwiftUI
import System
import UniformTypeIdentifiers
import DebouncedOnChange


typealias DispatchFn = ((ModelActions) -> ())
typealias NotifyFn = ((AppMessage) -> ())
typealias NavigateFn = ((Route, Route.Action) -> Void)
typealias PushNavigationFn = ((Route) -> Void)
typealias ReplaceNavigationFn = ((Route) -> Void)
typealias PopNavigationFn = (() -> Void)


extension EnvironmentValues {
  //@Entry var appDelegate
  
    // Uber Variables
  @Entry var appViewModel: AppViewModel = Container.shared.appViewModel()
  
  @Entry var dispatcher: DispatchFn = { _ in }
  @Entry var notify: NotifyFn = { _ in }
  
    // Navigation State
  @Entry var pushState: PushNavigationFn = { _ in }
  @Entry var popState: PopNavigationFn = {  }
  @Entry var replaceState: ReplaceNavigationFn = { _ in }
  @Entry var location: URL = Container.shared.appViewModel().location
  @Entry var route: Route = .main
  @Entry var page: Route.Page = .main
  
    // UI State
  @Entry var appPanels: Set<AppPanels> = []
  @Entry var currentSheet: AppSheet? = nil
  
  @Entry var photoGridState = PhotoGridState()
  @Entry var colorModel = Container.shared.colorModel()
  @Entry var cursorState = Container.shared.cursorState()
  @Entry var directoryTree = Container.shared.directoryTree()
  
  
    // Content Items
  @Entry var dbContentItems: [ContentItem] = []
  @Entry var dbContentItemsVisible: [ContentItem] = []
  @Entry var dbContentItemsHiddenCount: Int = 0
  @Entry var dbContentItemsMissingCount: Int = 0
  @available(*, deprecated, message: "Same as Defaults[.photoGridItemLimit]")
  @Entry var itemDisplayCount: Int = PreferencesContainer.shared.userPreferences().forKey(.photoGridItemLimit)
  @Entry var dbContentItemCount: Int = 0
  @Entry var queryResultCount: Int = 0
  
    /// Parameters used to populate the content items currently displayed
  @Entry var dbContentItemParameters: IndxRequestParams = Container.shared.appViewModel().dbIndexParameters
  
    // Detail Item
  @Entry var dbItemDetail: ContentItem? = nil
  
    // Bookmarks
  @Entry var dbBookmarks: [BookmarkInfoRecord] = []
  @Entry var dbLocations: [FilePath] = []
  
    // Work Queues
  @Entry var dbQueues: [QueueIndexesRecord] = []
  
    // TODO: I forget, what was this for?
  @Entry var releventContentType: UTType?
}


struct BrowseEnvironmentViewModifier: ViewModifier {
  @Injected(\Container.appViewModel) var appVM
  @Injected(\Container.cursorState) var cursor
  @Injected(\Container.colorModel) var colorModel
  
  @Environment(\.colorScheme) var systemScheme
  @Environment(\.enabledFlags) var devFlags
  @Environment(\.replaceState) var replace
  
  // @Query(ListIndexInfoRequest(parameters: Container.shared.appViewModel().dbIndexParameters)) var dbContentItems
  @Query(CountIndexesRequest(parameters: Container.shared.appViewModel().dbIndexParameters)) var dbIndexCount
  @Query(GetIndexInfoRequest(contentId: nil)) var dbItemDetail
  @Query(ListQueueIndexesRequest()) var dbQueues
  @Query(ListBookmarksRequest()) var dbBookmarks
  @Query(ListIndexLocationsRequest()) var dbLocations
  
  @Default(.backgroundColor) var userPreferenceColor
  
  
  var hiddenItemCount: Int {
    max(0, dbIndexCount - Defaults[.photoGridItemLimit])
  }
  
  var missingItemsCount: Int {
    appVM.contentItems.whereFileExists(false).count
  }
  
  var visibleItems: [IndexInfoRecord] {
    appVM.contentItems.whereFileExists()
  }
  
  func body(content: Content) -> some View {
    Group {
      ZStack {
        content
          .visible(dbErrorsClear)
        
        DatabaseErrorView(errorMap: queryErrors)
          .hidden(dbErrorsClear)
      }
      .environment(\.location, appVM.location)
      .environment(\.route, appVM.currentRoute)
      .environment(\.page, appVM.currentRoute.page)
      .environment(\.appPanels, appVM.activeAppPanels)
      .environment(\.currentSheet, appVM.activeSheet)
      .environment(\.dbContentItems, appVM.contentItems)
      .environment(\.dbContentItemsVisible, visibleItems)
      .environment(\.dbContentItemsHiddenCount, hiddenItemCount)
      .environment(\.dbContentItemsMissingCount, missingItemsCount)
      .environment(\.dbContentItemCount, dbIndexCount)
      .environment(\.dbContentItemParameters, appVM.dbIndexParameters)
      .environment(\.queryResultCount, dbIndexCount)
      .environment(\.dbItemDetail, dbItemDetail)
      .environment(\.dbLocations, dbLocations)
      .environment(\.dbQueues, dbQueues)
      .environment(\.dbBookmarks, dbBookmarks)
    }
    .onChange(of: appVM.dbIndexParameters, debounceTime: .milliseconds(200)) {
      onQueryParamsChanged()
//      DispatchQueue.main.asyncAfter(.milliseconds(1200)) {
//        onQueryParamsChanged()
//      }
    }
    .onChange(of: appVM.detailItemPointer) {
      $dbItemDetail.contentId.wrappedValue = appVM.detailItemPointer?.contentId
    }
    .onChange(of: systemScheme, initial: true) {
      colorModel.update(systemScheme)
    }
    .onChange(of: userPreferenceColor, initial: true) {
      colorModel.update(userPreferenceColor)
    }
  }
  
  var queryErrors: Dictionary<String, Optional<any Error>> { [
    //"$dbContentItems": $dbContentItems.error,
    "$dbIndexCount":   $dbIndexCount.error,
    "$dbBookmarks":    $dbBookmarks.error,
    "$dbItemDetail":   $dbItemDetail.error,
    "$dbQueues":       $dbQueues.error,
    "$dbLocations":    $dbLocations.error
  ]}
  
  var dbErrorsClear: Bool {
    queryErrors.compactMapValues{ $0 }.isEmpty
  }
  
  func onQueryParamsChanged() {
    //$dbContentItems.parameters.wrappedValue = appVM.dbIndexParameters.clone()
    
    DispatchQueue.main.asyncAfter(.seconds(0.8)) {
      $dbIndexCount.parameters.wrappedValue = appVM.dbIndexParameters.clone()
    }
  }
}


extension View {
  func withBrowseEnv() -> some View {
    modifier(BrowseEnvironmentViewModifier())
  }
}
