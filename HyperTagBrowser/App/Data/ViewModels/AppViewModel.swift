// Created on 9/2/24 by robinsr

import Combine
import CoreSpotlight
import CustomDump
import Defaults
import DequeModule
import Factory
import Foundation
import GRDB
import GRDBQuery
import IdentifiedCollections
import IssueReporting
import Observation
import SwiftUI
import System
import UniformTypeIdentifiers

@Observable
final class AppViewModel: FolderObserverDelegate, Sendable {

  private typealias Tags = [FilteringTag]
  private typealias Filters = [FilteringTag.Filter]
  private typealias Pointers = [ContentPointer]

  @ObservationIgnored
  private let logger = EnvContainer.shared.logger("AppViewModel")

  // MARK: - Dependencies

  @ObservationIgnored
  @Injected(\Container.fileService) private var fs

  @ObservationIgnored
  @Injected(\Container.spotlightService) private var spotlight

  @ObservationIgnored
  @Injected(\Container.clipboardService) private var clippy

  @ObservationIgnored
  @Injected(\Container.thumbnailStore) private var thumbnailStore

  @ObservationIgnored
  @Injected(\IndexerContainer.indexService) private var indexer

  @ObservationIgnored
  @Injected(\IndexerContainer.dbReader) private var dbQueue

  @ObservationIgnored
  @Injected(\IndexerContainer.dbWriter) private var dbWriter

  @ObservationIgnored
  @Injected(\IndexerContainer.databaseObserver) private var dbObserver

  @ObservationIgnored
  @Injected(\Container.metricsRecorder) var metrics

  // MARK: - Preferences

  @ObservationIgnored
  @Injected(\PreferencesContainer.userProfile) private var userProfile

  @ObservationIgnored
  @Injected(\PreferencesContainer.userPreferences) public var userPrefs

  @ObservationIgnored
  @Injected(\PreferencesContainer.stageSuite) public var stagePrefs

  // MARK: - View Model Dependencies

  @ObservationIgnored
  @Injected(\Container.detailViewModel) private var detailVM

  @ObservationIgnored
  @Injected(\Container.cursorState) private var cursor

  @ObservationIgnored
  private let indexingQueue = DispatchQueue(
    label: "\(Constants.appdomain).indexingQueue",
    qos: .userInitiated,
    attributes: .concurrent)

  @ObservationIgnored
  private var cancellable: GRDB.DatabaseCancellable?

  @ObservationIgnored
  private var previousAction: ModelActions = .appDidLoad

  //
  // MARK: - View Model Properties
  //

  var currentProfile: ActiveUserProfile {
    userProfile
  }

  var databaseContext: GRDBQuery.DatabaseContext {
    .readOnly { dbQueue }
  }

  var databasePath: String {
    dbQueue.path
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
  // MARK: UI State - Messages/Alerts
  //

  //var messageQueue: Deque<AppMessage> = []
  var messageQueue: [AppMessage] = []

  var message: AppMessage? {
    self.messageQueue.first
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
    if !location.volumeIsBrowsable { return false }
    if !location.volumeIsWritable { return false }
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

  var location: URL {
    switch currentRoute {
      case .folder(let path):
        return path.fileURL
      case .content(let pointer):
        return pointer.contentLocation
      case .main:
        return PreferencesContainer.shared.startingLocation().fileURL
    }
  }
  
  var path: FilePath {
    switch currentRoute {
      case .folder(let path):
        return path
      case .content(let pointer):
      return pointer.contentPath
      case .main:
        return PreferencesContainer.shared.startingLocation()
    }
  }

  var detailItemPointer: ContentPointer? {
    switch currentRoute {
      case .content(let pointer):
        return pointer
      default:
        return nil
    }
  }

  var ignorePaths: Set<FilePath> = [
    FilePath("~/Library").expandingTilde()
  ]

  //
  // MARK: UI State - Searching
  //

  private var searchCancellable: AnyCancellable?
  var searchQuery = SearchQuery(queryString: "")
  var searchState: SearchState = .ready
  var searchResults: [ContentItem] = []

  //
  // MARK: - Initializers
  //

  init() {
    let _ = FolderObserver(withDelegate: self, url: .userDirectory)

    Task {
      for await value in Defaults.updates(.photoGridItemLimit) {
        self.dispatch(.setItemLimit(to: value))
      }
    }

    Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [self] _ in
      let oldestMsgTime: Date = .now.adding(.second, value: -10)
      // Ensure we have the latest location set
      messageQueue = messageQueue.filter { $0.timestamp >= oldestMsgTime }
    }

    let cont = Continuator()

    cont.withContinousObservation(of: self.navigationPath) { [self] navStack in
      if case .folder(let path) = navStack.last {
        setQueryLocation(to: path)
      }
    }

    cont.withContinousObservation(of: self.query) { [self] filters in
      self.logger.emit(.info, "Fetching content items from AppViewModel...")

      self.updateContentItems()
    }
  }

  private var currentTask: Task<Void, Never>? = nil


  // TODO: Finish moving expensive work to background
  func updateContentItems() {
    currentTask?.cancel()

    let timer = metrics.startTimer(
      named: "appvm.updateContentItems.time", attributes: query.metricValues)

    currentTask = Task {
      self.contentItems = await Task.detached(priority: .userInitiated) {
        do {
          return try self.indexer.getIndexInfo(matching: self.query)
        } catch {
          self.logger.emit(.error, "Error fetching content items: \(error)")
          return []
        }
      }.value
    }

    timer.stop()

    currentTask = nil
  }

  var isLoadingContentItems: Bool {
    currentTask != nil
  }


  //
  // MARK: - Notifications
  //


  func send(_ message: AppMessage) {
    logger.emit(message.level.loglevel, message.body)

    withAnimation {
      messageQueue.append(message)
    }
  }

  func unsend(_ message: AppMessage) {
    _ = withAnimation {
      messageQueue.removeFirst(where: { $0.body == message.body })
    }
  }

  func send(_ msg: String) {
    send(AppMessage(msg, .info))
  }

  func send(_ msg: ErrorMsg) {
    send(AppMessage(msg.description, .error))
  }

  func send(ok msg: String) {
    send(AppMessage(msg, .success))
  }

  func send(ok msgs: [String]) {
    send(AppMessage(msgs.joined(separator: " "), .success))
  }

  func send(reject msg: String) {
    send(AppMessage(msg, .warning))
  }

  func send(reject err: AppViewModelError) {
    send(AppMessage(err.localizedDescription, .warning))
  }

  func send(err msg: String) {
    send(AppMessage(msg, .error))
  }

  func send(_ pattern: String, args: [any CVarArg]) {
    send(AppMessage(pattern, .info, arguments: args))
  }

  func send(ok pattern: String, args: [any CVarArg]) {
    send(AppMessage(pattern, .success, arguments: args))
  }

  func send(err pattern: String, args: [any CVarArg]) {
    send(AppMessage(pattern, .error, arguments: args))
  }

  //
  // MARK: - Action Dispatcher
  //

  func dispatch(_ action: ModelActions, from page: Route) {
    if navigationPath.last != page {
      self.navigationPath.append(page)
    }

    self.dispatch(action)
  }

  func navigate(_ route: Route) {
    if currentRoute != route {
      dispatch(.navigate(to: route))
    }
  }

  func dispatch(_ action: ModelActions) {

    let dispatchWorkItem = DispatchWorkItem {
      self._dispatch(action)
    }

    var taskTail: DispatchWorkItem = dispatchWorkItem

    if action.requiresRefresh {
      let refreshWorkItem = DispatchWorkItem {
        self._dispatch(.reloadQuery)
      }

      taskTail = taskTail.chainTask(refreshWorkItem)
    }

    let timer = metrics.startAction(named: action.id, attributes: [:])

    indexingQueue.async(execute: dispatchWorkItem)

    timer.stop()
  }

  private func _dispatch(_ action: ModelActions) {
    if Defaults[.devFlags].contains(.model_logActionDescription) {
      logger.emit(.action, "Dispatching action: \(action.description)")
    } else {
      logger.emit(.action, "Dispatching action: \(action.id.quoted)")
    }

    previousAction = action

    switch action {

      case .appDidLoad:
        reportIssue("Initial state action **appDidLoad** should never be dispatched")

      case .noop:
        break

      case .notify(let message):
        send(message)

      case .navigate(let route, let action):
        doNavigate(to: route, action: action)

      case .popRoute:
        doPopRoute()

      case .clearMessage(let message):
        doClearMessage(message)

      case .copyToClipboard(let label, let value):
        doCopyToClipboard(value, label: label)

      case .showSheet(let sheet):
        doShowSheet(sheet)

      case .togglePanel(let panel):
        doTogglePanel(panel)

      case .showPanel(let panel):
        doShowPanel(panel)

      case .hidePanel(let panel):
        doHidePanel(panel)

      case .reloadQuery:
        doReloadQuery()

      case .setListMode(let mode):
        setQueryListMode(mode)

      case .toggleListMode:
        toggleQueryListMode()

      case .setSortMode(let mode):
        setQuerySortMode(mode)

      case .cycleSortMode:
        doCycleSortMode()

      case .setFilterOperator(let opr):
        setQueryFilterOperator(opr)

      case .toggleFilterOperator:
        toggleQueryFilterOperator()

      case .setVisibilityFilter(let visibility):
        setQueryVisibilityFilter(visibility)

      case .setItemLimit(to: let limit):
        setQueryItemLimit(to: limit)

      case .setTagFiltering(let enabled):
        setQueryTagFiltering(isEnabled: enabled)

      case .addFilter(let filter, let effect):
        doAddFilter(FilteringTag.Filter(tag: filter, effect: effect))

      case .removeFilter(let filter):
        doRemoveFilter(filter)

      case .replaceFilter(let filter, with: let replacement):
        doReplaceFilter(filter, with: replacement)

      case .invertFilter(let filter):
        doInvertFilter(filter)

      case .clearFilters:
        doClearFilters()

      case .applySavedQuery(let id):
        doApplySavedQuery(id: id)

      case .createSavedQuery(let filters, named: let name):
        doCreateSavedQuery(named: name, with: filters)

      case .deleteSavedQuery(let id):
        doDeleteSavedQuery(id: id)

      case .renameSavedQuery(let id, to: let name):
        doRenameSavedQuery(id: id, to: name)

      case .updateSavedQuery(let id, with: let filters):
        doUpdateSavedQuery(id: id, with: filters)

      case .loadSavedQuery(let id):
        doLoadSavedQuery(withId: id)

      case .stashTag(let tag, into: let stashId):
        doUpdateTagStash(id: stashId, appending: [tag])

      case .stashTags(let tags, into: let stashId):
        doUpdateTagStash(id: stashId, appending: tags)

      case .unstashTag(let tag, from: let stashId):
        doUpdateTagStash(id: stashId, removing: [tag])

      case .clearTagStash(id: let stashId):
        doClearTagStash(id: stashId)

      case .editTags(of: let pointers):
        doEditTags(of: pointers)

      case .associateTag(let tag, to: let scope):
        doAssociateTags([tag], to: scope)

      case .associateTags(let tags, to: let scope):
        doAssociateTags(tags, to: scope)

      case .dissociateTag(let tag, from: let scope):
        doDissociateTag(tag, scope)

      case .enqueueItems(let pointers, into: let tag):
        doInsertContent(pointers, into: tag)

      case .replaceTags(let tags, of: let scope):
        doReplaceTags(tags, of: scope)

      case .normalizeTags(let initial, let keeping, let pointers):
        doNormalizeTags(from: initial, keeping: keeping, pointers: pointers)

      case .editName(of: let pointer):
        doEditName(of: pointer)

      case .updateIndex(let update):
        doUpdateIndex(with: update)

      case .updateIndexes(let patches):
        doUpdateIndexes(using: patches)

      case .updateThumbnails(of: let records):
        doUpdateThumbnails(of: records)

      case .replaceContents(_, _):
        send(reject: "ReplaceContents action is not supported in AppViewModel")

      case .revealItem(let url):
        doRevealFinderItem(at: url)

      case .removeTag(let tag, let scope):
        doRemoveTag(tag, scope)

      case .renameTag(let tag, let value, let scope):
        doRenameTag(tag, value, scope)

      case .relabelTag(let tag, to: let tagType, let scope):
        doRelabelTag(tag, tagType, scope)

      case .toggleTag(_, _):
        send(reject: "Tag inversion not yet supported")

      case .indexItems(inFolder: let url):
        doIndexDirectory(url)

      case .removeIndex(of: let pointers):
        doRemoveIndex(of: pointers)

      case .bookmarkContent(let content):
        doCreateBookmark(to: content)

      case .unbookmarkContent(let content):
        doDeleteBookmarks(to: content)
      
      case .deleteBookmark(let bookmark):
        doDeleteBookmark(bookmark)
      
      case .bookmarkCurrentLocation, .unbookmarkCurrentLocation:
        toggleCurrentLocationBookmark()

      case .createQueue(let name):
        doCreateQueue(named: name)

      case .backupDatabase:
        doBackupDatabase()

      case .createProfile(let name):
        doCreateProfile(named: name)

      case .setActiveProfile(to: let profileId):
        doSetActiveProfile(id: profileId)

      case .deleteProfile(let profileId, let dataRetention):
        doDeleteProfile(profileId, dataRetention: dataRetention)

      case .updateSearchIndex(with: let pointers):
        doUpdateSearchIndex(of: pointers)

      case .deleteFromSearchIndex(items: let pointers):
        doDeleteFromSearchIndex(of: pointers)

      case .searchForTerm(let term):
        dispatch(.showSheet(.searchSheet(query: term.rawValue)))

      case .searchForTag(let tag):
        dispatch(.showSheet(.searchSheet(query: tag.asSearchString)))

      case .startSearch(let query):
        startContentSearch(with: query)

      case .setSearchState(let state):
        doSetSearchState(to: state)

      case .dismissRequested:
        handleDismissRequest()

      case .testDispatchQueues:
        break
    }
  }

  /**
   * Handles random escape key events
   */
  private func handleDismissRequest() {

    // If a modal is showing, dismiss it, returning after the first UI change.
    if activeSheet != nil {
      dispatch(.showSheet(.none))
      return
    }

    // If a panel is showing, close it, returning after the first UI change.
    for panel in AppPanels.closePriority {
      if activeAppPanels.contains(panel) {
        dispatch(.hidePanel(panel))
        return
      }
    }
  }


  private func doNavigate(to route: Route, action: Route.Action = .push) {
    guard route != currentRoute else {
      return
    }

    switch action {
      case .push:
        logger.emit(.info.off, "Appending route: \(route)")

        navigationPath.append(route)
      case .replace:
        logger.emit(.info.off, "Replacing route: \(route)")

        if let last = navigationPath.last {
          navigationPath.replace(last, with: route)
        } else {
          navigationPath.append(route)
        }
    }
  }


  private func doPopRoute() {
    if navigationPath.hasPrevious {
      navigationPath.removeLast()
    }
  }


  private func doClearMessage(_ message: AppMessage) {
    unsend(message)

    if message.level == .restart {
      send("Restarting app...")

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        self.restart()
      }
    }
  }


  private func doCopyToClipboard(_ value: String, label: String = "Text") {
    clippy.write(text: value)

    send(ok: "\(label) copied to clipboard")
  }


  private func doAddFilter(_ filter: FilteringTag.Filter) {
    query.tagsMatching = query.tagsMatching.appending(filter)
  }


  private func doRemoveFilter(_ filter: FilteringTag) {
    query.tagsMatching = query.tagsMatching.remove(filter)
  }


  private func doReplaceFilter(_ filter: FilteringTag, with newTag: FilteringTag) {
    query.tagsMatching = query.tagsMatching.replace(filter, with: newTag)
  }


  private func doInvertFilter(_ filter: FilteringTag) {
    query.tagsMatching = query.tagsMatching.invertFilter(filter)
  }


  private func doClearFilters() {
    query.tagsMatching = query.tagsMatching.removeAll()
  }


  private func setQueryFilterOperator(_ opr: FilterOperator) {
    query.tagsMatching = query.tagsMatching.setOperator(opr)
  }


  private func toggleQueryFilterOperator() {
    query.tagsMatching = query.tagsMatching.toggleOperator()
  }


  private func setQueryTagFiltering(isEnabled: Bool) {
    query.tagsMatching = query.tagsMatching.setEnabled(isEnabled)
  }


  private func setQuerySortMode(_ mode: SortType = .createdAtDesc) {
    query.sortBy = mode
  }


  private func doCycleSortMode() {
    let sortOptions = SortType.allCases
    let currentInd = sortOptions.indices(of: query.sortBy).first ?? -1
    let nextInd = sortOptions.indices[circular: currentInd + 1]

    if let nextSortType = sortOptions[safe: nextInd] {
      send(ok: "Sorting by \(nextSortType.description)")

      query.sortBy = nextSortType
    }
  }

  private func setQueryLocation(to path: FilePath) {
    query.root = path
  }


  private func setQueryVisibilityFilter(_ visibility: ContentItemVisibility) {
    query.visibility = visibility
  }


  private func setQueryItemLimit(to limit: Int) {
    query.limit = limit
  }


  private func doReloadQuery() {
    query.id = .randomIdentifier(32)
  }


  private func setQueryListMode(_ mode: ListMode) {
    query.mode = mode
  }


  private func toggleQueryListMode() {
    query.mode = query.mode.toggle(.cached)

    send(ok: "\(query.mode.type.description) \(query.root.baseName.quoted)")
  }


  private func doApplySavedQuery(id: BrowseFilters.ID) {
    logger.emit(.info, "Applying saved query with ID: \(id)")

    do {
      guard let savedQueryRecord = try indexer.getSavedQuery(withId: id) else {
        send(reject: "Saved query with ID \(id) not found")
        return
      }

      dbSavedId = savedQueryRecord.id
      query = savedQueryRecord.query

      send(ok: "Applied filters from \(savedQueryRecord.name.quoted)")
    } catch {
      send(ErrorMsg("Error applying saved query", error))
    }
  }


  private func doCreateSavedQuery(named name: String, with filters: BrowseFilters) {
    logger.emit(.info, "Creating new saved query with filters: \(json: filters)")

    do {
      let saved = try indexer.createSavedQuery(named: name, using: filters)

      send(ok: "Saved query '\(name)' created with ID \(saved.id)")
    } catch {
      send(ErrorMsg("Error creating saved query", error))
    }
  }


  private func doDeleteSavedQuery(id: BrowseFilters.ID) {
    logger.emit(.info, "Deleting saved query with ID: \(id)")

    do {
      let deleted = try indexer.deleteSavedQuery(withId: id)

      if deleted {
        send(ok: "Saved query with ID \(id) deleted")
      } else {
        send(reject: "Saved query with ID \(id) not found")
      }
    } catch {
      send(ErrorMsg("Error creating saved query", error))
    }
  }


  private func doRenameSavedQuery(id: BrowseFilters.ID, to name: String) {
    logger.emit(.info, "Renaming saved query with ID: \(id) to name: \(name)")

    do {
      let _ = try indexer.renameSavedQuery(withId: id, to: name)

      send(ok: "Saved query renamed to '\(name)'")
    } catch {
      send(ErrorMsg("Error creating saved query", error))
    }
  }


  private func doUpdateSavedQuery(id: BrowseFilters.ID, with filters: BrowseFilters) {
    logger.emit(.info, "Updating saved query with ID: \(id) with filters: \(json: filters)")

    do {
      let _ = try indexer.updateSavedQuery(withId: id, using: filters)

      send(ok: "Saved query with ID \(id) updated")
    } catch {
      send(ErrorMsg("Error creating saved query", error))
    }
  }

  private func doLoadSavedQuery(withId id: BrowseFilters.ID) {
    logger.emit(.info, "Loading saved query with ID: \(id)")

    do {
      if let saved = try indexer.getSavedQuery(withId: id) {
        dispatch(.showSheet(.updateSavedQuerySheet(record: saved)))
      } else {
        send(reject: "Saved query with ID \(id) not found")
      }
    } catch {
      send(ErrorMsg("Error loading saved query", error))
    }
  }


  private func doUpdateTagStash(id: TagStash.ID, appending tag: FilteringTag) {
    doUpdateTagStash(id: id, appending: [tag])
  }

  private func doUpdateTagStash(id: TagStash.ID, appending tags: [FilteringTag]) {
    let items = (tagStashes[id]?.contents ?? []).union(tags)
    let newStash = TagStash(id: id, contents: items)

    tagStashes.updateValue(newStash, forKey: id)
  }

  private func doUpdateTagStash(id: TagStash.ID, removing tags: [FilteringTag]) {
    if let stash = tagStashes[id] {
      let newStash = TagStash(id: id, contents: stash.contents.subtracting(tags))

      tagStashes.updateValue(newStash, forKey: id)
    }
  }

  private func doClearTagStash(id: TagStash.ID) {
    tagStashes.updateValue(TagStash(id: id), forKey: id)
  }

  func tagsStashed(in stashId: TagStash.ID) -> [FilteringTag] {
    tagStashes[stashId]?.contents.asArray ?? []
  }


  private func doShowSheet(_ sheet: AppSheet) {
    switch sheet {
      case .none:
        activeSheet = nil
      default:
        activeSheet = sheet
    }
  }


  private func doShowPanel(_ panel: AppPanels) {
    if !activeAppPanels.contains(panel) {
      self.dispatch(.togglePanel(panel))
    } else {
      logger.emit(.warning, "Panel \(panel.title.quoted) already showing")
    }
  }


  private func doHidePanel(_ panel: AppPanels) {
    if activeAppPanels.contains(panel) {
      activeAppPanels.remove(panel)
    } else {
      logger.emit(.warning, "Panel \(panel.title.quoted) not found in active panels")
    }
  }


  private func doRemoveIndex(of pointers: Pointers) {
    do {
      let count = try indexer.deleteIndexes(withIds: pointers.ids)

      send(ok: "Removed \("items", qty: count) from index")
    } catch {
      send(ErrorMsg("Could not remove items from index", error))
    }
  }


  private func doCreateBookmark(to content: ContentItem) {
    guard content.conforms(to: .folder) else {
      send(reject: "Cannot create bookmark for non-folder item")
      return
    }
    
    do {
      let bookmark = try indexer.createBookmark(to: content.id)
      
      customDump(bookmark, name: "Created Bookmark")
      
      send(ok: "Created new bookmark")
    } catch {
      send(ErrorMsg("Error creating bookmark for folder: \(content.name)", error))
    }
  }


  private func doDeleteBookmark(_ bookmark: BookmarkItem) {
    do {
      if let deleted = try indexer.deleteBookmark(withId: bookmark.id) {
        send(ok: "Bookmark to '\(bookmark.name)' deleted")
      } else {
        send(err: "Bookmark not found")
      }
    } catch {
      send(ErrorMsg("Error deleting bookmark", error))
    }
  }

  private func doDeleteBookmarks(to content: ContentItem) {
    do {
      let deleted = try indexer.deleteBookmarks(to: content.id)

      if deleted.count > 0 {
        send(ok: "Bookmark to '\(content.filepath.baseName)' deleted")
      } else {
        send(err: "Bookmark not found")
      }
    } catch {
      send(ErrorMsg("Error deleting bookmark", error))
    }
  }

  
  private func toggleCurrentLocationBookmark() {
    do {

      if let bookmark = try indexer.findBookmark(withPath: path) {
        self.doDeleteBookmark(bookmark)
        
        let _ = try indexer.deleteBookmark(withId: bookmark.id)
        
        send(ok: "Bookmark at \(path.baseName.quoted) deleted")
      } else {
        
      }
    } catch {
      send(ErrorMsg("Error toggling bookmark for current location", error))
    }
  }

  private func doCreateQueue(named name: String) {
    do {
      let queue = try indexer.createQueue(named: name)
      send(ok: "Created new queue '\(name)' (\(queue.id))")
    } catch {
      send(ErrorMsg("Error creating queue", error))
    }
  }


  private func doBackupDatabase() {
    let timestamp = DateFormatter.filename.string(from: .now)
    let archiveName = "userdb-\(currentProfile.id)-\(timestamp).zip"

    let dbFilePath = currentProfile.dbFile.filepath
    let archivePath = dbFilePath.directory.appending(archiveName)

    Task.detached(priority: .userInitiated) { [self] in
      do {
        try fs.createZipArchive(of: dbFilePath, at: archivePath)
        send(ok: "Database backup created at \(archivePath)")
      } catch {
        send(ErrorMsg("Error creating backup", error))
      }
    }

    send(ok: "Creating new database backup...")
  }


  private func doTogglePanel(_ panel: AppPanels) {
    let panelShowing = activeAppPanels.contains(panel)

    if let parent = panel.parent {
      let situation = (activeAppPanels.contains(parent), panelShowing)

      switch situation {
        case (true, true):
          // parent+sub-panel showing, hide sub-panel
          activeAppPanels.remove(panel)
        case (true, false):
          // parent showing, not sub-panel, show sub-panel
          activeAppPanels.insert(panel)
        case (false, true):
          // parent hidden, sub-panel showing, show parent
          activeAppPanels.insert(parent)
        case (false, false):
          // parent hidden, sub-panel hidden, show both
          activeAppPanels.insert(parent)
          activeAppPanels.insert(panel)
      }
      return
    } else {
      // Regular toggling logic
      activeAppPanels.toggleExistence(panel)
    }
  }


  private func doEditTags(of pointers: [ContentPointer]) {
    do {
      let records = try indexer.getIndexInfo(withId: pointers.map(\.contentId))

      if records.count == 1 {
        return dispatch(
          .showSheet(
            .editItemTagsSheet(item: records.first!, tags: records.first!.tags))
        )
      }

      let allTags = records.map(\.tags)

      var commonTags = Set(allTags.first ?? [])

      for tags in allTags.dropFirst() {
        commonTags.formIntersection(tags)
      }

      dispatch(
        .showSheet(
          .editItemsTagsSheet(items: records, tags: commonTags.asArray))
      )
    } catch {
      send(ErrorMsg("Error fetching tags for items", error))
    }
  }


  private func doAssociateTags(_ tags: Tags, to scope: ContentScope) {
    if let disallowedErr = disallowScopeTypes([.global, .exclude, .atURL], scope: scope) {
      send(reject: disallowedErr)
      return
    }
    
    do {
      var results: [IndexTagRecord] = []
      
      if case .matching(let params) = scope {
        results = try indexer.associateTags(tags, matching: params)
      }
      
      if scope.ids.notEmpty {
        results = try indexer.associateTags(tags, toContentIds: scope.ids)
      }
      
      let contentIds = results.map(\.contentId).uniqued()

      if tags.count == 1, let tag = tags.first {
        send(ok: "Tagged \("item", qty: contentIds.count) with \(tag.value.quoted)")
      } else {
        send(ok: "Tagged \("item", qty: contentIds.count) with \("tag", qty: tags.count)")
      }
    } catch {
      send(reject: .AssociationError(error))
    }
  }


  private func doDissociateTag(_ tag: FilteringTag, _ scope: ContentScope) {
    if let disallowedErr = disallowScopeTypes([.global, .exclude, .atURL], scope: scope) {
      send(reject: disallowedErr)
      return
    }
    
    do {
      var contentIds = scope.ids
      
      if case .matching(let params) = scope {
        contentIds = try indexer.getIndexIds(matching: params)
      }
    
      let count = try indexer.removeTag(tag, fromContent: contentIds)

      send(ok: "Removed \("tag associations", qty: count)")
    } catch {
      send(reject: .AssociationError(error))
    }
  }


  private func doInsertContent(_ pointers: [ContentPointer], into tag: FilteringTag) {
    do {
      let _ = try indexer.associateTag(tag, toContentIds: pointers.map(\.contentId))

      send(ok: "Added item to \(tag.description)")
    } catch {
      send(ErrorMsg("Error adding content to tag", error))
    }
  }


  private func doReplaceTags(_ tags: [FilteringTag], of scope: ContentScope) {
    if let disallowedErr = disallowScopeTypes([.global, .exclude, .atURL, .matching], scope: scope) {
      send(reject: disallowedErr)
      return
    }
    
    guard scope.ids.notEmpty else {
      send(reject: "No content selected to update tags")
      return
    }
    
    do {
      let result = try indexer.replaceTags(forContent: scope.ids, withSet: tags)

      send(ok: "Updated \("item", qty: scope.ids.count) with \("tag", qty: result.count)")
    } catch {
      send(ErrorMsg("Error updating tags", error))
    }
  }


  private func doNormalizeTags(from initial: Tags, keeping: Tags, pointers: Pointers) {
    let fromSet = Set(initial)
    let toSet = Set(keeping)
    let dropSet = fromSet.subtracting(toSet)


    do {
      let (added, removed) = try indexer.modifyTags(
        forContent: pointers.map(\.contentId),
        ensure: toSet.asArray,
        remove: dropSet.asArray
      )

      send(ok: [
        "Updated \("item", qty: pointers.count):",
        "\("tags", qty: added.count) added,",
        "\("tags", qty: removed.count) removed",
      ])
    } catch {
      send(ErrorMsg("Error modifying tags", error))
    }
  }


  private func doEditName(of pointer: ContentPointer) {
    do {
      if let result = try indexer.getIndexInfo(withId: pointer.contentId) {
        dispatch(.showSheet(.renameContentSheet(item: result)))
      } else {
        send(err: "No index found for item \(pointer.contentId)")
      }
    } catch {
      send(ErrorMsg("Error fetching index", error))
    }
  }


  private func doUpdateIndex(with update: IndexRecord.Update) {
    do {
      let _ = try indexer.updateIndexes(with: update)
      send(ok: update.successMessage)
    } catch {
      send(ErrorMsg(update.failedMessage, error))
    }
  }


  private func doUpdateIndexes(using patches: [IndexRecord.Update]) {
    do {
      let results = try patches.map { patch in
        try indexer.updateIndexes(with: patch)
      }

      send(ok: "Updated \("Item", qty: results.count)")
    } catch {
      send(ErrorMsg("Error updating indexes", error))
    }
  }


  private func doUpdateThumbnails(of records: [IndexRecord]) {
    Task.detached(priority: .background) {
      do {
        for index in records {
          try self.thumbnailStore.clearThumbnail(forContent: index.id)
        }
        self.send(ok: "Updated thumbnails for \("items", qty: records.count)")
      } catch {
        self.send(ErrorMsg("Error updating thumbnails", error))
      }
    }
  }


  private func doRevealFinderItem(at url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }


  private func doRemoveTag(_ tag: FilteringTag, _ scope: BatchScope) {
    do {
      let count = try indexer.removeTag(tag, scope: scope)

      send(ok: "\("associations", qty: count) of tag '\(tag.value, max: 20)' removed")
    } catch {
      send(ErrorMsg("Error deleting tags", error))
    }
  }


  private func doRenameTag(_ tag: FilteringTag, _ value: String, _ scope: BatchScope) {
    guard let newTag = tag.type.makeTag(value) else {
      send(err: "Invalid tag value")
      return
    }

    do {
      switch scope {
        case .all:
          let (_, dbTagItems) = try indexer.renameTag(tag, to: newTag)

          send(ok: "Renamed tag on \("records", qty: dbTagItems.count) (all records)")
        case .visible:
          let updated = try indexer.renameTag(tag, to: newTag, matching: query)

          send(ok: "Renamed tag on \(updated) records")
        case .hidden:
          unimplemented("removeFilteringTag(.hidden)")
        case .selected:
          unimplemented("removeFilteringTag(.selected)")
        case .unselected:
          unimplemented("removeFilteringTag(.unselected)")
      }
    } catch {
      send(ErrorMsg("Error deleting tags", error))
    }
  }


  private func doRelabelTag(
    _ tag: FilteringTag, _ tagType: FilteringTag.TagType, _ scope: BatchScope
  ) {
    guard let newTag = tagType.makeTag(tag.value) else {
      send(err: "Invalid tag value '\(tag.value)' for tag type \(tagType)")
      return
    }

    do {
      switch scope {
        case .all:
          let (_, dbTagItems) = try indexer.renameTag(tag, to: newTag)

          send(ok: "Renamed tag on \("records", qty: dbTagItems.count) (all records)")
        default:
          unimplemented("removeFilteringTag")
          send(err: "Scope \(scope) not supported")
      }
    } catch {
      send(ErrorMsg("Error deleting tags", error))
    }
  }


  private func doCreateProfile(named name: String) {
    let profile = ExternalUserProfile.create(profileName: name)

    Defaults[.profileKeys].insert(profile.id)

    send(ok: "Created new profile '\(name)' (\(profile.id))")
  }


  private func doSetActiveProfile(id profileId: ExternalUserProfile.ID) {
    Defaults[.activeProfile] = profileId

    Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
      self.send(AppMessage("App restart required to apply changes", .restart))
    }
  }


  private func doDeleteProfile(
    _ profileId: ExternalUserProfile.ID, dataRetention: DataRetentionOption = .preserve
  ) {
    let profile = ExternalUserProfile(id: profileId)

    let removeProfileTask = DispatchWorkItem {
      // Remove all keys from UserDefaults suite
      profile.suite.removeAll()
      // Remove profileId from list of profiles
      Defaults[.profileKeys].remove(profileId)
    }

    let removeProfileDataTask = DispatchWorkItem { [self] in
      do {
        // Move this profile's database file to trash
        //let dbFileDeleted = try fs.moveToTrash(profile.dbFile.filepath)
        _ = try fs.moveToTrash(profile.dbFile.filepath)
        // Move this profile's plist to trash
        //let prefsDelete = try fs.moveToTrash(profile.prefsPath.filepath)
        _ = try fs.moveToTrash(profile.prefsPath.filepath)

        Task {
          // Clean up this profile's search index
          try await spotlight.deleteAllItems()
        }
      } catch {
        send(ErrorMsg("Error deleting profile data", error))
      }
    }

    var taskTail: DispatchWorkItem = removeProfileTask

    if dataRetention == .discard {
      taskTail = taskTail.chainTask(removeProfileDataTask)
    }

    let deletingActiveProfile = currentProfile.id == profile.id

    if deletingActiveProfile {
      logger.emit(
        .info,
        "Deleting currently active profile (\(profile.name.quoted)); Will reset with default profile"
      )

      taskTail = taskTail.chainTask(
        .init {
          // Set the active profile to the default profile
          self.doSetActiveProfile(id: DefaultUserProfile.id)
        })
    }

    if !deletingActiveProfile {
      taskTail = taskTail.chainTask(
        .init {
          let okMessage =
            switch dataRetention {
              case .discard: "Profile deleted and data removed"
              case .preserve: "Profile deleted"
            }

          self.send(ok: okMessage)
        })
    }

    self.indexingQueue.async(execute: removeProfileTask)
  }


  private func doUpdateSearchIndex(of pointers: [ContentPointer]) {
    do {
      let indexInfoRecords = try indexer.getIndexInfo(withId: pointers.map(\.contentId))

      Task.detached(priority: .background) {
        do {
          try await self.spotlight.indexItems(indexInfoRecords)

          self.send(ok: "Re-indexed \("items", qty: indexInfoRecords.count)")
        } catch {
          self.send(ErrorMsg("Error updating search index", error))
        }
      }
    } catch {
      send(ErrorMsg("Error updating search index", error))
    }
  }


  private func doDeleteFromSearchIndex(of pointers: [ContentPointer]) {
    Task.detached(priority: .background) { [weak self] in
      do {
        try await self?.spotlight.deleteItems(pointers.ids)
      } catch {
        self?.send(ErrorMsg("Error deleting from search index", error))
      }
    }
  }


  private func setupSearchObserver() {
    searchCancellable = spotlight.searchStateSubject.sink { results in
      self.doSetSearchState(to: results)
    }
  }


  private func doSetSearchState(to state: SearchState) {
    self.searchState = state

    switch state {
      case .returned(results: let items):
        self.searchResults =
          items
          .uniqued(by: \.uniqueIdentifier)
          .compactMap { IndexInfoRecord.from(attributeSet: $0.attributeSet) }

      case .errorCode(let code):
        self.send(reject: "Spotlight search error: \(code)")

      case .errorMessage(let message):
        self.send(reject: "Spotlight search error: \(message)")

      default:
        break
    }
  }


  private func startContentSearch(with query: SearchQuery) {
    searchQuery = query

    let searchType = userPrefs.forKey(.searchMethod)

    switch searchType {
      case .databaseQuery:
        return executeDatabaseSearch(query: query)
      case .searchQuery:
        return spotlight.executeSearchQuery(query)
      case .userQuery:
        return spotlight.executeTermSearch(query)
      case .userSearch:
        return spotlight.executeUserQuery(query)
    }
  }


  private func executeDatabaseSearch(query: SearchQuery) {
    let queryTerms = query.searchTerms

    var tagTokens =
      queryTerms
      .filter { $0.kind != .related }
      .map { FilteringTag.Filter(tag: $0.asFilter, effect: .inclusive) }

    let nameTokens =
      queryTerms
      .filter { $0.kind == .related }
      .map { $0.value }

    if tagTokens.isEmpty && nameTokens.isEmpty {
      // If no search terms are provided, use a random token to avoid all-matching query
      tagTokens.append(FilteringTag.tag(.randomIdentifier(40)).filterAs(.inclusive))
    }

    let params = BrowseFilters(
      root: query.searchRoot,
      mode: .recursive(.uncached),
      sortBy: query.searchSorting,
      tagsMatching: .init(tagTokens, operator: query.searchTermOperator),
      nameMatching: .init(nameTokens, operator: query.searchTermOperator),
      limit: query.paging.pageSize,
      offset: query.paging.offset,
      includeColumns: [.fileExists, .isFolder, .tagCount]
    )

    customDump(params, name: "Database search params")

    do {
      let contentItems = try indexer.getIndexInfo(matching: params)

      let resultItems = contentItems.map { item in
        CSSearchableItem(
          uniqueIdentifier: item.index.contentId.value,
          domainIdentifier: "userdb",
          attributeSet: item.attributeSet,
        )
      }

      dispatch(.setSearchState(.returned(results: resultItems)))
    } catch {
      send(ErrorMsg("Error searching database", error))
    }
  }


  private func doIndexDirectory(_ url: URL) {

    // Ignore changes to this directory temporarily
    //ignorePaths.toggleExistence(url.filepath, shouldExist: true)
    ignorePaths.insert(url.filepath)

    let indexingTask = DispatchWorkItem {
      self.send("Indexing directory: \(url.filepath.baseName)")

      Task.detached {
        do {
          let result = try self.indexer.indexDirectory(at: url.filepath)

          DispatchQueue.main.async {
            if !result.duplicates.isEmpty {
              let duplicates = result.duplicates

              self.send(
                reject:
                  "Duplicate files encountered while indexing: \("duplicate item", qty: duplicates.count) found"
              )
            } else {
              let add = result.added
              let del = result.removed
              let same = result.unchanged

              self.send(
                ok: "\(add.count) new, \(del.count) removed, \(same.count) unchanged indexed")
            }
          }
        } catch {
          self.send(ErrorMsg("Error while indexing folder \(url.filepath)", error))
        }
      }
    }

    let postIndexTask = DispatchWorkItem {
      // This will be executed after the indexingTask is completed
      // Reload the query to reflect changes in UI
      self.doReloadQuery()

      DispatchQueue.main.asyncAfter(.milliseconds(500)) {
        self.ignorePaths.remove(url.filepath)
      }
    }

    indexingTask.notify(queue: DispatchQueue.main) {
      postIndexTask.perform()
    }

    self.indexingQueue.async(execute: indexingTask)
  }
  
  private func disallowScopeTypes(_ scopes: [ContentScope.Cases], scope: ContentScope) -> AppViewModelError? {
    guard scopes.contains(scope.caseType) else {
      return nil
    }
    
    switch scope.caseType {
      case .global:
        return .globalTag
      case .exclude:
        return .exBasedTagging
      case .matching:
        return .paramBasedTagging
      case .atURL:
        return .urlBasedTagging
      default:
      return .NotImplemented("Scope type \(scope.caseType.rawValue) not implemented for this action")
    }
  }

  private func terminate() {
    NSApplication.shared.terminate(nil)
  }

  private func restart(afterDelay seconds: TimeInterval = 0.5) -> Never {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "sleep \(seconds); open \"\(Bundle.main.bundlePath)\""]
    task.launch()

    NSApp.terminate(self)
    exit(0)
  }

  func bindToPanel(_ panel: AppPanels) -> Binding<Bool> {
    Binding {
      self.activeAppPanels.contains(panel)
    } set: { show in
      if show {
        self.dispatch(.showPanel(panel))
      } else {
        self.dispatch(.hidePanel(panel))
      }
    }
  }


  // MARK: - FolderObserverDelegate

  func onFamiliarChange(item contentItem: ContentItem, url changedURL: URL) {
    let contentId = contentItem.id
    let indexPath = contentItem.index.filepath
    let realPath = changedURL.filepath

    let fileWasRenamed = indexPath.baseName != realPath.baseName
    let fileWasRelocated = indexPath.directory != realPath.directory

    var updates: [IndexRecord.Update] = []

    if fileWasRelocated {
      updates.append(.location(of: [contentId], with: realPath.directory))
    }

    if fileWasRenamed {
      updates.append(.name(of: contentId, with: realPath.baseName))
    }

    guard let finalPatch = updates.last else { return }

    for patch in updates {
      do {
        let _ = try indexer.syncIndexes(with: patch)
      } catch {
        send(ErrorMsg(patch.failedMessage, error))
        return
      }
    }

    //send(ok: finalPatch.successMessage)
    logger.emit(.info, finalPatch.successMessage)
  }

  func onUnknownChange(at: URL) {
    logger.emit(
      .debug.off,
      "Unknown change detected at \(at.filepath). This might be a new file or an unsupported change."
    )
  }
}
