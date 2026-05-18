// created on 11/25/25 by robinsr

import Combine
import CoreSpotlight
import Factory
import GRDB


@MainActor
@Observable
final class SearchModel {
  
  @ObservationIgnored
  private let logger = CustomLogger("SearchModel", level: .debug)
  
  @ObservationIgnored
  private let spotlight = Container.shared.spotlightService()
  
  @ObservationIgnored
  private let indexer = IndexerContainer.shared.indexService()
  
  @ObservationIgnored
  private let msg = Container.shared.messagesModel()
  
  @ObservationIgnored
  private let bookmarksRepo = RepositoryContainer.shared.bookmarksRepo()
  
  private var bookmarksCancellable: AnyCancellable?
  private var currentBookmarkRequest: ListBookmarksRequest?
  
  @ObservationIgnored
  private let tagsRepo = RepositoryContainer.shared.tagsRepo()
  
  private var tagsRepoCancellable: AnyCancellable?
  private var currentTagsRequest: ListCountedTagsRequest?
  
  private let tagQuerySubject = CurrentValueSubject<String, Never>("")
  private var tagQueryCancellable: AnyCancellable?
  
  var bookmarks: [BookmarkInfoRecord] = []
  
  var suggestedTags: [CountedTagRecord] = []
  
  var queryString: String = "" {
    didSet { tagQuerySubject.send(queryString) }
  }
  
  var tagQueryString: String = ""
  
  var queryLocation: URL = PreferencesContainer.shared.startingLocation().fileURL
  
  var querySort: SortType = .initial
  
  var queryMatch: FilterOperator = .and
  
  var queryPage: Int = 0
  
  var query: SearchQuery {
    SearchQuery(
      queryString: queryString,
      options: [],
      location: queryLocation.filepath,
      sorting: querySort,
      joining: queryMatch,
      paging: .init(pageNumber: queryPage)
    )
  }
  
  var queryTerms: [SearchTerm] {
    query.searchTerms
  }
  
  var searchResults: [ContentItem] = []
  
  var searchState: SearchState = .ready {
    didSet {
      self.onNewSearchState(searchState)
    }
  }
  
//  var searchMethod: SearchMethod {
//    userPrefs.forKey(.searchMethod)
//  }
  
  var locationOptions: [LocationGroup] { [
    .named("Default Folder", PreferencesContainer.shared.startingLocation().fileURL),
    .user,
    .parent(of: queryLocation),
    .contents(of: queryLocation),
    .adjacent(to: queryLocation),
    .named("Bookmarked Folders", bookmarks.prefix(8).map(\.content.url))
  ] }
  
  
  
  init() {
    tagQueryCancellable?.cancel()
    tagQueryCancellable = tagQuerySubject
      .removeDuplicates()
      .filter { !$0.isEmpty }
      .debounce(for: .milliseconds(800), scheduler: RunLoop.main)
      .sink { [weak self] value in
        self?.tagQueryString = value.lastWord.trimmingCharacters(in: .symbols.union(.punctuationCharacters))
      }
  }
  
  private func onNewSearchState(_ state: SearchState) {
    logger.emit(.debug, "New SearchState: \(state.description)")
    
    if case .returned(let results) = searchState {
      self.fetchResultItems(results)
    }
    
    if case .errorMessage(let message) = state {
      logger.emit(.error, "SearchState.errorMessage: \(message)")
      
      if let additionalMsg = state.errorMessage {
        logger.emit(.error, "SearchState.errorMessage: \(additionalMsg)")
      }
    }
    
    if case .errorCode(let errCode) = state {
      logger.emit(.error, "SearchState.errorCode: \(errCode)")
    }
  }
  
  private func fetchResultItems(_ items: [SpotlightResult]) {
    Task {
      do {
        self.searchResults = try await indexer.getContentItems(withId: items.map(\.contentId))
      } catch {
        self.searchState = .errorMessage("Failed to retrieve content items: \(error.localizedDescription)")
      }
    }
  }
  
  private func searchIndex(query: SearchQuery) async -> SearchState {
    logger.emit(.debug, "Calling indexer.search with query: \(query.description)")
    
    do {
      let resultItems = try await indexer.search(query)
      return .returned(results: resultItems)
    } catch let indxError as IndexerServiceError {
      return .errorMessage(indxError.description)
    } catch {
      return .errorMessage("Search failed: \(error.legibleLocalizedDescription)")
    }
  }
  
    // MARK: - Public API
  
  public func startTagObservation(_ name: String) {
    let request = ListCountedTagsRequest(parameters: .init(query: queryString))
    
    // same request as before, don’t touch the observation
    guard request != currentTagsRequest else { return }
    
    currentTagsRequest = request
    tagsRepoCancellable?.cancel()
    tagsRepoCancellable = tagsRepo.observeTags(using: currentTagsRequest!)
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] items in
          self?.suggestedTags = items
        }
      )
  }
  
  public func startBookmarkObservation(_ name: String) {
    let request = ListBookmarksRequest()
    
    // same request as before, don’t touch the observation
    guard request != currentBookmarkRequest else { return }
    
    currentBookmarkRequest = request
    
    bookmarksCancellable?.cancel()
    bookmarksCancellable = bookmarksRepo.observeBookmarks(using: currentBookmarkRequest!)
      .sink(
          receiveCompletion: { _ in },
          receiveValue: { [weak self] items in
            self?.bookmarks = items
          }
      )
  }
  
  public func startSearch() async {
    logger.emit(.debug, "Starting new search with query: \(query.spotlightQuery)")
    
    searchState = .searching
    
    let searchMethod = PreferencesContainer.shared.prefs().forKey(.searchMethod)
    
    if case .databaseQuery = searchMethod {
      searchState = await searchIndex(query: query)
      return
    }
    
    Task {
      do {
        let results = try await spotlight.search(method: searchMethod, query: query)
        
        await MainActor.run {
          self.searchState = .returned(results: results)
        }
      } catch {
        await MainActor.run {
          self.searchState = .errorMessage(error.localizedDescription)
        }
      }
    }
  }
  
  public func appendWord(_ words: String) {
    queryString = queryString.appendingWord(words)
    
    Task { await startSearch() }
  }
  
  public func appendTerm(_ term: SearchTerm) {
    guard !queryTerms.contains(term) else { return }
    
    queryString = queryString.appendingWord(term.rawValue)
    
    Task { await startSearch() }
  }
  
  public func replaceWord(_ words: String, with phrase: String) {
    queryString = queryString.replacingMatches(of: words, options: [.caseInsensitive]) { _, str in
      phrase
    }
    
    Task { await startSearch() }
  }
  
  public func takeTagSuggestion(_ tag: FilteringTag) {
    if queryTerms.contains(tag.asSearchTerm) { return }
    
    if tag.value.contains(tagQueryString, caseSensitive: false) {
      replaceWord(tagQueryString, with: tag.asSearchString)
    } else {
      appendWord(tag.asSearchString)
    }
  }
  
  public func updateIndex(adding pointers: [ContentPointer]) {
    Task {
      do {
        let indexInfoRecords = try await indexer.getContentItems(withId: pointers.map(\.contentId))
        
        do {
          try await self.spotlight.indexItems(indexInfoRecords)
          msg.send(ok: "Re-indexed \("items", qty: indexInfoRecords.count)")
        } catch {
          msg.send(ErrorMsg("Error updating search index", error))
        }
      } catch {
        msg.send(ErrorMsg("Error updating search index", error))
      }
    }
  }
  
  public func updateIndex(removing pointers: [ContentPointer]) {
    Task {
      do {
        try await self.spotlight.deleteItems(pointers.ids)
      } catch {
        msg.send(ErrorMsg("Error deleting from search index", error))
      }
    }
  }
}
