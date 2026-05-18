// created on 11/24/25 by robinsr

import Defaults
import Factory
import Foundation


@MainActor
class AppDispatcher {
  
  private let timer = Container.shared.timer()
  private let logger = EnvContainer.shared.logger("AppDispatcher")
  
  private let app = Container.shared.appViewModel()
  private let search = Container.shared.searchModel()
  private let messages = Container.shared.messagesModel()
  
  private var previousAction: ModelActions = .appDidLoad

  private let taskDispatchQueue = DispatchQueue(
    label: "\(Constants.appdomain).dispatcher",
    qos: .userInitiated,
    attributes: .concurrent)
  
  func callAsFunction(_ action: ModelActions) {
    self.dispatch(action)
  }
  
  public func dispatch(_ action: ModelActions, from page: Route) {
    if app.navigationPath.last != page {
      app.navigationPath.append(page)
    }

    self.dispatch(action)
  }

  public func navigate(_ route: Route) {
    if app.currentRoute != route {
      dispatch(.navigate(to: route))
    }
  }

  public func dispatch(_ action: ModelActions) {
    let metric = MetricSource().tagged(action.id)

    let dispatchAction = DispatchWorkItem {
      DispatchQueue.main.async {
        self._dispatch(action)
      }
    }
    
    let reloadQuery = DispatchWorkItem {
      DispatchQueue.main.async {
        self._dispatch(.reloadQuery)
      }
    }

    var taskChain: DispatchWorkItem = dispatchAction

    if action.requiresRefresh {
      taskChain = taskChain.chainTask(reloadQuery)
    }
    
    timer.timeExecution(using: metric) {
      taskDispatchQueue.asyncAndWait(execute: dispatchAction)
    }
  }

  private func _dispatch(_ action: ModelActions) {
    if Defaults[.devFlags].contains(.model_logActionDescription) {
      logger.emit(.action, "Dispatching action: \(action.description)")
    } else {
      logger.emit(.action, "Dispatching action: \(action.id.quoted)")
    }

    previousAction = action

    switch action {
      
      // MARK: Navigation Actions
    case .navigate(let route, let action):
      app.doNavigate(to: route, action: action)
    case .popRoute:
      app.doPopRoute()
    case .dismissRequested:
      app.handleDismissRequest()
      
      // MARK: UI Messaging Actions
    case .clearMessage(let message):
      app.doClearMessage(message)
    case .notify(let message):
      messages.send(message)
      
      // MARK: Configuring UI Actions
    case .showSheet(let sheet):
      app.doShowSheet(sheet)
    case .showPanel(let panel):
      app.doShowPanel(panel)
    case .hidePanel(let panel):
      app.doHidePanel(panel)
    case .togglePanel(let panel):
      app.doTogglePanel(panel)
      
        // MARK: Browse Parameter Actions
    case .reloadQuery:
      app.doReloadQuery()
    case .cycleSortMode:
      app.doCycleSortMode()
    case .setListMode(let mode):
      app.setQueryListMode(mode)
    case .toggleListMode:
      app.toggleQueryListMode()
    case .setSortMode(let mode):
      app.setQuerySortMode(mode)
    case .toggleFilterOperator:
      app.toggleQueryFilterOperator()
    case .setFilterOperator(let opr):
      app.setQueryFilterOperator(opr)
    case .setVisibilityFilter(let visibility):
      app.setQueryVisibilityFilter(visibility)
    case .setItemLimit(to: let limit):
      app.setQueryItemLimit(to: limit)
    case .setTagFiltering(let enabled):
      app.setQueryTagFiltering(isEnabled: enabled)
      
      // MARK: Browse Filter Actions
    case .addFilter(let filter, let effect):
      app.doAddBrowseFilter(FilteringTag.Filter(tag: filter, effect: effect))
    case .removeFilter(let filter):
      app.doRemoveBrowseFilter(filter)
    case .replaceFilter(let filter, with: let replacement):
      app.doReplaceBrowseFilter(filter, with: replacement)
    case .invertFilter(let filter):
      app.doInvertBrowseFilter(filter)
    case .clearFilters:
      app.doClearBrowseFilters()
      
      // MARK: Saved Query Actions
    case .applySavedQuery(let id):
      app.doApplySavedQuery(id: id)
    case .createSavedQuery(let filters, named: let name):
      app.doCreateSavedQuery(named: name, with: filters)
    case .deleteSavedQuery(let id):
      app.doDeleteSavedQuery(id: id)
    case .renameSavedQuery(let id, to: let name):
      app.doRenameSavedQuery(id: id, to: name)
    case .updateSavedQuery(let id, with: let filters):
      app.doUpdateSavedQuery(id: id, with: filters)
    case .loadSavedQuery(let id):
      app.doLoadSavedQuery(withId: id)

      // MARK: TagStash Actions
    case .stashTag(let tag, into: let stashId):
      app.doUpdateTagStash(id: stashId, appending: [tag])
    case .stashTags(let tags, into: let stashId):
      app.doUpdateTagStash(id: stashId, appending: tags)
    case .unstashTag(let tag, from: let stashId):
      app.doUpdateTagStash(id: stashId, removing: [tag])
    case .clearTagStash(id: let stashId):
      app.doClearTagStash(id: stashId)
      
      // MARK: Associating Tag Actions
    case .associateTag(let tag, to: let scope):
      app.doAssociateTags([tag], to: scope)
    case .associateTags(let tags, to: let scope):
      app.doAssociateTags(tags, to: scope)
    case .dissociateTag(let tag, from: let scope):
      app.doDissociateTag(tag, scope)
    case .replaceTags(let tags, of: let scope):
      app.doReplaceTags(tags, of: scope)
    case .removeTag(let tag, let scope):
      app.doRemoveTag(tag, scope)
    case .renameTag(let tag, let value, let scope):
      app.doRenameTag(tag, value, scope)
    case .relabelTag(let tag, to: let tagType, let scope):
      app.doRelabelTag(tag, tagType, scope)
    case .toggleTag(_, _):
      messages.send(reject: "Tag inversion not yet supported")
    case .normalizeTags(let initial, let keeping, let pointers):
      app.doNormalizeTags(from: initial, keeping: keeping, pointers: pointers)
      
      // MARK: Modifying Content Actions
    case .editName(of: let pointer):
      app.doEditName(of: pointer)
    case .editTags(of: let pointers):
      app.doEditTags(of: pointers)
    case .applyIndexPatch(let patch):
      app.doUpdateIndex(with: patch)
    case .updateThumbnails(of: let records):
      app.doUpdateThumbnails(of: records)
      
      // MARK: File Actions
    case .revealItem(let url):
      app.doRevealFinderItem(at: url)
    case .replaceContents(_, _):
      messages.send(reject: "ReplaceContents action is not supported in AppViewModel")
      
      // MARK: Managing Index Actions
    case .indexItems(inFolder: let url):
      Task {
        await app.doIndexDirectory(url)
      }
    case .removeIndex(of: let pointers):
      app.doRemoveIndex(of: pointers)
    case .backupDatabase:
      app.doBackupDatabase()
      
      // MARK: Bookmarking Actions
    case .bookmarkContent(let content):
      app.doCreateBookmark(to: content)
    case .unbookmarkContent(let content):
      app.doDeleteBookmarks(to: content)
    case .deleteBookmark(let bookmark):
      app.doDeleteBookmark(bookmark)
    case .bookmarkCurrentLocation:
      app.toggleCurrentLocationBookmark()
    case .unbookmarkCurrentLocation:
      app.toggleCurrentLocationBookmark()
      
      // MARK: Queue Actions
    case .createQueue(let name):
      app.doCreateQueue(named: name)
    case .enqueueItems(let pointers, into: let tag):
      app.doInsertContent(pointers, into: tag)
      
      // MARK: Profile Actions
    case .createProfile(let name):
      app.doCreateProfile(named: name)
    case .deleteProfile(let profileId, let dataRetention):
      app.doDeleteProfile(profileId, dataRetention: dataRetention)
    case .setActiveProfile(to: let profileId):
      app.doSetActiveProfile(id: profileId)
    
      // MARK: Search Actions
    case .updateSearchIndex(with: let pointers):
      search.updateIndex(adding: pointers)
    case .deleteFromSearchIndex(items: let pointers):
      search.updateIndex(removing: pointers)
    case .searchForTerm(let term):
      dispatch(.showSheet(.searchSheet(query: term.rawValue)))
    case .searchForTag(let tag):
      dispatch(.showSheet(.searchSheet(query: tag.asSearchString)))
      
      // MARK: Utility Actions
    case .appDidLoad:
      logger.emit(.warning, "Initial state action **appDidLoad** should never be dispatched")
    case .copyToClipboard(let label, let value):
      app.doCopyToClipboard(text: value, label: label)
    case .copyDataToClipboard(let label, let data):
      app.doCopyToClipboard(data: data, label: label)
    case .ejectVolume(let url):
      app.doEjectVolume(at: url)
      
      // MARK: No-op Action
    case .noop:
      break

        // MARK: Testing Actions
    case .testDispatchQueues:
      break
    }
  }
}
