// Created on 9/2/24 by robinsr

import Defaults
import Factory
import GRDB
import SwiftUI
import System


@MainActor
@Observable
final class AppViewModel {

  typealias Tags = [FilteringTag]
  typealias Filters = [FilteringTag.Filter]
  typealias Pointers = [ContentPointer]

  @ObservationIgnored
  let logger = EnvContainer.shared.logger("AppViewModel")

  // MARK: - Dependencies

  @ObservationIgnored
  let thumbnailStore = ThumbnailContainer.shared.store()

  @ObservationIgnored
  @Injected(\IndexerContainer.indexService) var indexer
  
  @ObservationIgnored
  @Injected(\Container.messagesModel) var messages

  @ObservationIgnored
  @Injected(\Container.metricsRecorder) var metrics

  // MARK: - Preferences

  @ObservationIgnored
  @Injected(\PreferencesContainer.userProfile) private var userProfile

  @ObservationIgnored
  @Injected(\PreferencesContainer.prefs) public var userPrefs

  // MARK: - View Model Dependencies

  @ObservationIgnored
  @Injected(\Container.detailViewModel) private var detailVM

  @ObservationIgnored
  @Injected(\Container.cursorState) private var cursor


  //
  // MARK: - View Model Properties
  //

  var currentProfile: ActiveUserProfile {
    userProfile
  }


  //
  // MARK: UI State - Content Items
  //

  var contentItems: [ContentItem] = []

  /**
   * Returns the set of contentItems that would be affected by an edit operation
   *
   * On the content page, this returns the single detail item.
   * On the main page, this returns the selected items in the cursor.
   */
  var editableContent: [ContentItem] {
    if currentRoute.page == .content, let detailItem = detailVM.contentItem {
      return [detailItem]
    }

    if currentRoute.page != .content && cursor.anySelected {
      return cursor.selection
    }

    return []
  }


  //
  // MARK: UI State - Panels/Sheets
  //

  var activeSheet: AppSheet? = nil          // AppSheet.none
  var activeAppPanels: Set<AppPanels> = []

  // MARK: UI State - Tag Stashes
  var tagStashes: [TagStash.ID: TagStash] = [.default: .init()]
  var stashedTags: Set<FilteringTag> {
    tagStashes[.default]?.contents ?? []
  }

  //
  // MARK: Query State
  //

  /// The current browse filters used to fetch content items from the database.
  var query: BrowseFilters = .defaults.contentItems

  /// Previous name of ``query``, leaving it here to support older references.
  var dbIndexParameters: BrowseFilters { self.query }

  // Properties that are bound to the current state of `BrowseFilters`
  var listMode: ListMode { query.mode }
  var sorting: SortType { query.sortBy }
  var filters: FilteringTagMultiParam { query.tagsMatching }

  /// ID of the SavedQueryRecord last applied. Used as the target for `updateSavedQuery` actions.
  var dbSavedId: SavedQueryRecord.ID? = nil


  /**
   Returns a boolean indicating if the current browse parameters
   */
  var indexingDisabled: Bool {
    if listMode.type == .recursive { return false }
    if !currentURL.volumeIsBrowsable { return false }
    if !currentURL.volumeIsWritable { return false }
    return true
  }

  //
  // MARK: Navigation
  //

  var navigationPath: [Route] = [
    .folder(PreferencesContainer.shared.startingLocation())
  ]

  var currentRoute: Route {
    navigationPath.last ?? Route.main
  }
  
  var currentPage: Route.Page {
    navigationPath.last?.page ?? .main
  }

  var currentURL: URL {
    switch currentRoute {
      case .folder(let path): path.fileURL
      case .content(let pointer): pointer.contentLocation
      case .main: PreferencesContainer.shared.startingLocation().fileURL
    }
  }
  
  var currentPath: FilePath {
    switch currentRoute {
    case .folder(let path): path
    case .content(let pointer): pointer.contentPath
    case .main: PreferencesContainer.shared.startingLocation()
    }
  }
  
  var currentFolderName: String {
    currentPath.baseName
  }

  var detailItemPointer: ContentPointer? {
    switch currentRoute {
    case .content(let pointer): pointer
    default: nil
    }
  }


  //
  // MARK: - Initializers
  //
  
  var folderObserver: FolderObserver?
  var reloadDebouncer: OperationDebouncer?
  var observerTask: Task<Void, Never>?
  var queryChangeTask: Task<Void, Never>? = nil
  var taskDispatchQueue = DispatchQueue(label: "taskDispatchQueue")

  init() {
    Task {
      for await value in Defaults.updates(.photoGridItemLimit) {
        Container.shared.dispatcher().dispatch(.setItemLimit(to: value))
      }
    }
    
    let cont = Continuator()
    
    Task { @MainActor in
      cont.withContinousObservation(of: self.navigationPath) { [self] navStack in
        Task {
          if case .folder(let path) = navStack.last {
            self._setQueryLocation(to: path)
            self._startFolderObservation(at: path)
          }
        }
      }
      
      cont.withContinousObservation(of: self.query) { [self] filters in
        logger.emit(.debug, "Filters changed: \(filters)")
        self._onQueryChange(filters)
      }
    }
  }
  
  
  // TODO: Finish moving expensive work to background
  private func _onQueryChange(_ filters: BrowseFilters) {
    queryChangeTask?.cancel()

    let timer = metrics.startTimer(
      named: "appvm.updateContentItems.time", attributes: query.metricValues)

    queryChangeTask = Task {
      self.contentItems = await Task.detached(priority: .userInitiated) {
        do {
          let _indexer = IndexerContainer.shared.indexService()
          return try await _indexer.getContentItems(matching: filters)
        } catch {
          self.logger.emit(.error, "Error fetching content items: \(error)")
          return []
        }
      }.value
    }

    timer.stop()

    queryChangeTask = nil
    
    self.logger.emit(.info, "ContentItems refreshed")
  }

  var isLoadingContentItems: Bool {
    queryChangeTask != nil
  }

  func terminate() {
    NSApplication.shared.terminate(nil)
  }

  func restart(afterDelay seconds: TimeInterval = 0.5) -> Never {
    logger.emit(.info, "Restarting app")
    
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "sleep \(seconds); open \"\(Bundle.main.bundlePath)\""]
    task.launch()

    NSApp.terminate(self)
    exit(0)
  }
}
