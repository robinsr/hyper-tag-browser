// created on 9/27/24 by robinsr

import Foundation
import SwiftUI

enum ModelActions: CustomStringConvertible, Equatable {

  // MARK: - Navigation Actions

  case navigate(to: Route, _ update: Route.Action = .push)
  case popRoute

  // MARK: - UI Messaging Actions

  case clearMessage(AppMessage)
  case notify(_ message: AppMessage)

  // MARK: - Browse Parameter Actions

  case reloadQuery
  case cycleSortMode
  case setListMode(ListMode)
  case toggleListMode
  case setSortMode(SortType)
  case toggleFilterOperator
  case setFilterOperator(FilterOperator)
  case setVisibilityFilter(ContentItemVisibility)
  case setItemLimit(to: Int)
  case setTagFiltering(enabled: Bool)

  // MARK: - Configuring UI Actions

  case showSheet(_ sheet: AppSheet)
  case showPanel(_ panel: AppPanels)
  case hidePanel(_ panel: AppPanels)
  case togglePanel(_ panel: AppPanels)
  /// A generic dismiss action that can be used to close any open sheet or panel.
  case dismissRequested

  // MARK: - Browse Refinement Actions

  case addFilter(FilteringTag, FilteringTag.FilterEffect)
  case removeFilter(FilteringTag)
  case replaceFilter(FilteringTag, with: FilteringTag)
  case invertFilter(FilteringTag)
  case clearFilters

  // MARK: - Saved Query Actions

  case applySavedQuery(BrowseFilters.ID)
  case createSavedQuery(BrowseFilters, named: String)
  case deleteSavedQuery(BrowseFilters.ID)
  case renameSavedQuery(BrowseFilters.ID, to: String)
  case updateSavedQuery(BrowseFilters.ID, with: BrowseFilters)
  case loadSavedQuery(BrowseFilters.ID)


  // MARK: - TagStash Actions

  case stashTag(FilteringTag, into: TagStash.ID)
  case stashTags([FilteringTag], into: TagStash.ID)
  case unstashTag(FilteringTag, from: TagStash.ID)
  case clearTagStash(id: TagStash.ID)

  // MARK: - Associating Tag Actions

  case associateTag(FilteringTag, to: ContentScope)
  case associateTags([FilteringTag], to: ContentScope)
  case dissociateTag(FilteringTag, from: ContentScope)
  case replaceTags([FilteringTag], of: ContentScope)

  case removeTag(FilteringTag, scope: BatchScope)
  case renameTag(FilteringTag, to: String, scope: BatchScope)
  case relabelTag(FilteringTag, to: FilteringTag.TagType, scope: BatchScope)
  case toggleTag(FilteringTag, scope: BatchScope)

  /**
   "Normalizes" the tags of a set of content items by
    - Removing all associations for tags present in `initial` but not in `keeping`
    - Creating (if not already present) associations for tags present in `keeping`
   */
  case normalizeTags(initial: [FilteringTag], keeping: [FilteringTag], of: [ContentPointer])

  // MARK: - Modifying Content Actions

  case editName(of: ContentPointer)
  case editTags(of: [ContentPointer])
  case updateIndex(IndexRecord.Update)
  case updateIndexes([IndexRecord.Update])
  case updateThumbnails(of: [IndexRecord])


  // MARK: - File Actions

  /// Reveals URL in Finder
  case revealItem(URL)

  /// Writes the file contents of the file at the given URL to the file represented by the `ContentPointer`.
  case replaceContents(of: ContentPointer, with: URL)

  // MARK: - Managing Index Actions

  case indexItems(inFolder: URL)
  case removeIndex(of: [ContentPointer])
  case backupDatabase

  // MARK: - Bookmarking Actions

  case bookmarkContent(ContentItem)
  case unbookmarkContent(ContentItem)
  case deleteBookmark(BookmarkItem)
  case bookmarkCurrentLocation
  case unbookmarkCurrentLocation

  // MARK: - Queue Actions

  case createQueue(name: String)
  // TODO: Fix duplication — Same as `associateTag(FilteringTag, to: [ContentPointer])`
  case enqueueItems([ContentPointer], into: FilteringTag)
  // case dequeueItems([ContentPointer], from: FilteringTag)

  // MARK: - Profile Actions

  case createProfile(name: String)
  case deleteProfile(ExternalUserProfile.ID, data: DataRetentionOption = .preserve)
  case setActiveProfile(to: ExternalUserProfile.ID)

  // MARK: - Search Actions

  case startSearch(SearchQuery)
  case setSearchState(SearchState)
  case updateSearchIndex(with: [ContentPointer])
  case deleteFromSearchIndex(items: [ContentPointer])
  case searchForTerm(SearchTerm)
  case searchForTag(FilteringTag)

  // MARK: - Utility
  case appDidLoad
  case noop
  case copyToClipboard(label: String, value: String)


  // MARK: - Testing
  case testDispatchQueues


  var description: String {
    switch self {

      // MARK: Navigation Actions

      case .navigate(let to, let action):
        return "[navigate]: to \(describing: to) (\(action.rawValue))"
      case .popRoute:
        return "[popRoute]"

      // MARK: UI Messaging Actions

      case .clearMessage:
        return "[clearMessage]"
      case .notify(let message):
        return "[notify]: \(message)"

      // MARK: Browse Parameter Actions

      case .reloadQuery:
        return "[reloadQuery]"
      case .cycleSortMode:
        return "[cycleSortMode]"
      case .setListMode(let mode):
        return "[setListMode]: \(mode.description)"
      case .toggleListMode:
        return "[toggleListMode]"
      case .setSortMode(let sortType):
        return "[setSortMode]; sortType: \(describing: sortType)"
      case .setFilterOperator(let opr):
        return "[setFilterOperator]: \(opr.description)"
      case .toggleFilterOperator:
        return "[toggleFilterOperator]"
      case .setVisibilityFilter(let vis):
        return "[setVisibilityFilter]: \(vis.description)"
      case .setItemLimit(let itemLimit):
        return "[setItemLimit]: \(itemLimit)"
      case .setTagFiltering(let isEnabled):
        return "[setTagFiltering]: enabled=\(isEnabled)"

      // MARK: Configuring UI Actions

      case .showSheet(let sheet):
        return "[showSheet]: \(sheet.id)"
      case .showPanel(let panel):
        return "[showPanel]: \(panel)"
      case .hidePanel(let panel):
        return "[hidePanel]: \(panel)"
      case .togglePanel(let panel):
        return "[togglePanel]: \(panel)"
      case .dismissRequested:
        return "[dismissRequested]"

      // MARK: Browse Refinement Actions

      case .addFilter(let tag, let effect):
        return "[addFilter]: \(tag.description), \(effect.description))"
      case .removeFilter(let filter):
        return "[removeFilter]: \(filter.description)"
      case .replaceFilter(let filter, with: let replacement):
        return "[replaceFilter]: \(filter.description) with \(replacement.description)"
      case .invertFilter(let filter):
        return "[invertFilter]: \(filter.description)"
      case .clearFilters:
        return "[clearFilters]"


      // MARK: Saved Query Actions

      case .applySavedQuery(let id):
        return "[applySavedQuery]: id=\(id.quoted)"
      case .createSavedQuery(let filters, named: let name):
        return "[createSavedQuery]: filters.id=\(filters.id.quoted), name=\(name.quoted)"
      case .deleteSavedQuery(let id):
        return "[deleteSavedQuery]: id=\(id.quoted)"
      case .renameSavedQuery(let id, to: let name):
        return "[renameSavedQuery]: id=\(id.quoted), name=\(name.quoted)"
      case .updateSavedQuery(let id, with: let filters):
        return "[updateSavedQuery]: id=\(id.quoted) filters.id=\(filters.id)"
      case .loadSavedQuery(let id):
        return "[loadSavedQuery]: id=\(id.quoted)"

      // MARK: TagStash Actions

      case .stashTag(let tag, into: let id):
        return "[stashTag]: tag=\(tag), into=\(id)"
      case .unstashTag(let tag, from: let id):
        return "[unstashTag]: tag=\(tag), from=\(id)"
      case .stashTags(let tags, into: let id):
        return "[stashTag]: tags=\(tags), into=\(id)"
      case .clearTagStash(let id):
        return "[clearStash]: \(id)"

      // MARK: Associating Tag Actions

      case .associateTag(let tag, to: let scope):
        return "[associateTag]: to=\(scope.description), tag=\(tag)"
      case .associateTags(let tags, to: let scope):
        return "[associateTags]: to=\(scope.description), tag=\(tags.string)"
      case .dissociateTag(let tag, from: let scope):
        return "[dissociateTag]: from=\(scope.description), tag=\(tag)"
      case .replaceTags(let tags, of: let scope):
        return "[replaceTags]: of=\(scope.description), tags=\(tags)"
      case .removeTag(let fileTag, let scope):
        return "[removeTag]: \(fileTag.description) in \(scope.description)"
      case .renameTag(let fileTag, let to, let scope):
        return "[renameTag]: \(fileTag.description) to\(to) in \(scope.description)"
      case .relabelTag(let fileTag, to: let tagType, let scope):
        return "[relabelTag]: \(fileTag.description) to \(tagType.rawValue) in \(scope.description)"
      case .toggleTag(let fileTag, let scope):
        return "[toggleTag]: \(fileTag.description) in \(scope.description)"
      case .normalizeTags(let initial, let keeping, let pointers):
        return
          "[normalizeTags]: initial=\(initial.string), keeping=\(keeping.string)), of=[\(pointers.string))]"

      // MARK: Modifying Content Actions

      case .editName(of: let pointer):
        return "[editName]: of=\(pointer.contentId)"
      case .editTags(of: let pointers):
        return "[editTags]: of=\(pointers.string)"
      case .updateIndex(let update):
        return "[updateIndex]: \(update)"
      case .updateIndexes(let updates):
        return "[updateIndexes]: \(updates)"
      case .updateThumbnails(of: let records):
        return "[updateThumbnails]: of=[\(records.string)]"

      // MARK: File Actions

      case .revealItem(let url):
        return "[revealItem]: \(url.filepath)"
      case .replaceContents(of: let pointer, with: let newURL):
        return "[replaceContents]: of=\(pointer.contentId) with=\(newURL.filepath)"

      // MARK: Managing Index Actions

      case .indexItems(inFolder: let url):
        return "[indexItems]: inFolder=[\(url.filepath)]"
      case .removeIndex(of: let pointers):
        return "[removeIndex]: ids=[\(pointers.string)]"
      case .backupDatabase:
        return "[backupDatabase]"

      // MARK: Bookmarking Actions

      case .bookmarkContent(let content):
        return "[bookmarkContent]: content=\(content.filepath.string)"
      case .unbookmarkContent(let content):
        return "[unbookmarkContent]: content=\(content.filepath.string)"
      case .deleteBookmark(let bm):
        return "[deleteBookmark]: bookmark=\(bm.filepath.string)"
      case .bookmarkCurrentLocation:
        return "[bookmarkCurrentLocation]"
      case .unbookmarkCurrentLocation:
        return "[unbookmarkCurrentLocation]"

      // MARK: Queue Actions

      case .createQueue(let name):
        return "[createQueue]: name=\(name)"
      case .enqueueItems(let pointers, into: let tag):
        return "[enqueueItems]: ids=\(pointers.string) into==\(tag)"

      // MARK: Profile Actions

      case .createProfile(let name):
        return "[addProfile]: name=\(name)"
      case .deleteProfile(let profileId, let dataRetention):
        return "[deleteProfile]: profile=\(profileId), dataRetention=\(dataRetention)"
      case .setActiveProfile(to: let profileId):
        return "[setActiveProfile]: profileId=\(profileId)"

      // MARK: Search Actions

      case .startSearch(let query):
        return "[startSearch]: \(query)"
      case .setSearchState(let state):
        return "[setSearchState]: \(state.description)"
      case .updateSearchIndex(with: let pointers):
        return "[updateSearchIndex]: with=[\(pointers.string)]"
      case .deleteFromSearchIndex(items: let pointers):
        return "[purgeSearchIndex]: of=[\(pointers.string)]"
      // This should be .showSheet(.search(query: <term>))
      case .searchForTerm(let term):
        return "[searchForTerm]: term=\(term.rawValue)"
      // This should be .showSheet(.search(query: <tag>))
      case .searchForTag(let tag):
        return "[searchForTag]: tag=\(tag.rawValue)"


      // MARK: Utility Actions

      case .appDidLoad:
        return "[appDidLoad]"
      case .noop:
        return "[noop]"
      case .copyToClipboard(let label, let value):
        return "[copyToClipboard]: label=[\(label)] value=[\(value)]"

      // MARK: Testing

      case .testDispatchQueues:
        return "[testDispatchQueues]"
    }
  }

  var willAnimate: Bool {
    switch self {
      case .showSheet, .showPanel, .hidePanel, .togglePanel:
        return true
      default:
        return false
    }
  }

  var requiresRefresh: Bool {
    switch self {
      case .associateTag,
        .associateTags,
        .dissociateTag,
        .editTags,
        .indexItems,
        .normalizeTags,
        .reloadQuery,
        .replaceTags,
        .updateIndex,
        .updateIndexes,
        .updateSearchIndex:
        return true
      default:
        return false
    }
  }

  var id: String {
    switch self {
      case .addFilter: "addFilter"
      case .appDidLoad: "appDidLoad"
      case .applySavedQuery: "applySavedQuery"
      case .associateTag: "associateTag"
      case .associateTags: "associateTags"
      case .backupDatabase: "backupDatabase"
      case .bookmarkContent: "bookmarkContent"
      case .bookmarkCurrentLocation: "bookmarkCurrentLocation"
      case .clearFilters: "clearFilters"
      case .clearMessage: "clearMessage"
      case .clearTagStash: "clearTagStash"
      case .copyToClipboard: "copyToClipboard"
      case .createProfile: "createProfile"
      case .createQueue: "createQueue"
      case .createSavedQuery: "createSavedQuery"
      case .cycleSortMode: "cycleSortMode"
      case .deleteBookmark: "deleteBookmark"
      case .deleteFromSearchIndex: "deleteFromSearchIndex"
      case .deleteProfile: "deleteProfile"
      case .deleteSavedQuery: "deleteSavedQuery"
      case .dismissRequested: "dismissRequested"
      case .dissociateTag: "dissociateTag"
      case .editName: "editName"
      case .editTags: "editTags"
      case .enqueueItems: "enqueueItems"
      case .hidePanel: "hidePanel"
      case .indexItems: "indexItems"
      case .invertFilter: "invertFilter"
      case .loadSavedQuery: "loadSavedQuery"
      case .navigate: "navigate"
      case .noop: "noop"
      case .normalizeTags: "normalizeTags"
      case .notify: "notify"
      case .popRoute: "popRoute"
      case .relabelTag: "relabelTag"
      case .reloadQuery: "reloadQuery"
      case .removeFilter: "removeFilter"
      case .removeIndex: "removeIndex"
      case .removeTag: "removeTag"
      case .renameSavedQuery: "renameSavedQuery"
      case .renameTag: "renameTag"
      case .replaceContents: "replaceContents"
      case .replaceFilter: "replaceFilter"
      case .replaceTags: "replaceTags"
      case .revealItem: "revealItem"
      case .searchForTag: "searchForTag"
      case .searchForTerm: "searchForTerm"
      case .setActiveProfile: "setActiveProfile"
      case .setFilterOperator: "setFilterOperator"
      case .setItemLimit: "setItemLimit"
      case .setListMode: "setListMode"
      case .setSearchState: "setSearchState"
      case .setSortMode: "setSortMode"
      case .setTagFiltering: "setTagFiltering"
      case .setVisibilityFilter: "setVisibilityFilter"
      case .showPanel: "showPanel"
      case .showSheet: "showSheet"
      case .startSearch: "startSearch"
      case .stashTag: "stashTag"
      case .stashTags: "stashTags"
      case .testDispatchQueues: "testDispatchQueues"
      case .toggleFilterOperator: "toggleFilterOperator"
      case .toggleListMode: "toggleListMode"
      case .togglePanel: "togglePanel"
      case .toggleTag: "toggleTag"
      case .unbookmarkContent: "unbookmarkContent"
      case .unbookmarkCurrentLocation: "unbookmarkCurrentLocation"
      case .unstashTag: "unstashTag"
      case .updateIndex: "updateIndex"
      case .updateIndexes: "updateIndexes"
      case .updateSavedQuery: "updateSavedQuery"
      case .updateSearchIndex: "updateSearchIndex"
      case .updateThumbnails: "updateThumbnails"
      
    }
  }


  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.description == rhs.description
  }
}
