// created on 12/25/24 by robinsr

import Combine
import CoreSpotlight
import CustomDump
import Factory
import CoreFoundation
import CoreServices
import Foundation
import Observation
import UniformTypeIdentifiers


@Observable
final class SpotlightService {
  
  typealias Result = CSSearchableItem
  
  @ObservationIgnored
  private let logger = EnvContainer.shared.logger("SpotlightService")
  @ObservationIgnored
  private let quicklook = Container.shared.quicklookService()
  @ObservationIgnored
  private let indexName = Container.shared.spotlightServiceIndexName()
  @ObservationIgnored
  private let domainIdentifier = Container.shared.spotlightDomainIdentifier()
  @ObservationIgnored
  private let userProfileId = PreferencesContainer.shared.userProfileId()
  
  
  @ObservationIgnored
  lazy private var secureIndex: CSSearchableIndex = {
    if indexName == "defaullt" {
      return CSSearchableIndex.default()
    } else {
      return CSSearchableIndex(name: indexName, protectionClass: indexProtectionLevel)
    }
  }()
  
  var protectionClass: FileProtectionType {
    if indexName == "default" {
      return .none
    } else {
      return indexProtectionLevel
    }
  }
  
  var searchState: SearchState = .ready
  var queryBuilder: SearchQuery = SearchQuery()
  var searchQuery: CSSearchQuery?
  var resultItems: [CSSearchableItem] = []
  var resultSuggestions: [CSSuggestion] = []
  let indexProtectionLevel: FileProtectionType = .none
  
    /// A subject to emit search state updates.
  let searchStateSubject = PassthroughSubject<SearchState, Never>()
  
  init() {
//    CSUserQuery.prepare()
//    CSUserQuery.prepareProtectionClasses([indexProtectionLevel])
  }
  
  func query(of searchMethod: SearchMethod, using query: SearchQuery) {
    if case .databaseQuery = searchMethod {
      return
    }
    
    logger.emit(.info, "Querying index '\(indexName)' using \(searchMethod.debugDescription)")
    logger.emit(.info, "Query string: \(query.queryString)")
    
    switch searchMethod {
    case .searchQuery:
      executeSearchQuery(query)
    case .userSearch:
      executeTermSearch(query)
    case .userQuery:
      executeUserQuery(query)
    default:
      break;
    }
  }
  
  func awaitQueryResults(_ query: CSSearchQuery) {
    searchState = .searching
    searchQuery = query
    
    var results: [CSSearchableItem] = []
    
    Task {
      defer {
        self.logger.emit(.debug, "Query completed")
        
        DispatchQueue.main.sync {
          self.resultItems.append(contentsOf: results)
          
          let result = SearchState.returned(results: results)
          
          self.searchState = result
          self.searchStateSubject.send(result)
        }
      }
      
      do {
        for try await result in query.results {
          results.append(result.item)
        }
      } catch {
        self.onError(error)
      }
    }
  }
  
  private func onError(_ error: Error) {
    logger.emit(.error, ErrorMsg("Error executing query: \(error.localizedDescription) (\(type(of: error)))", error))
    searchState = .errorMessage(error.localizedDescription)
    
    if let code = error as? CSSearchQueryError {
      logger.emit(.error, "Error code: \(code)")
    }
  }
  
  /**
   * Executes a CSSearchQuery with `queryString` and `queryContext`.
   * Invoked for type ``SearchMethod/searchQuery`` ("Search Query").
   */
  func executeSearchQuery(_ query: SearchQuery) {
    let csSearchQuery = CSSearchQuery(
      queryString: query.spotlightQuery,
      queryContext: query.searchContext
    )
    
    awaitQueryResults(csSearchQuery)
  }
  
  /**
   * Executes a CSUserQuery with `userQueryString` and `userQueryContext`.
   * Invoked for type ``SearchMethod/userSearch`` ("User Search").
   */
  func executeTermSearch(_ query: SearchQuery) {
    /// Creates a new user query that searches for the specified term.
    let csUserQuery = CSUserQuery.init(
      userQueryString: query.queryString,
      userQueryContext: query.userContext
    )
    
    csUserQuery.protectionClasses = [indexProtectionLevel]
    
    awaitQueryResults(csUserQuery)
  }
  
  /**
   * Executes a CSUserQuery with `queryString` and `queryContext`.
   * Invoked for type ``SearchMethod/userQuery`` ("User Query").
   */
  func executeUserQuery(_ query: SearchQuery) {

    let csUserQuery = CSUserQuery(
      queryString: query.spotlightQuery,
      queryContext: query.searchContext
    )
    
    csUserQuery.protectionClasses = [indexProtectionLevel]
    
    awaitQueryResults(csUserQuery)
  }
  
  func prepareItemForIndex(_ item: any IndexableItem) -> CSSearchableItem {
    let itemAttributes = item.attributeSet
    
    if let debugJson = try? JSONEncoder().encode(itemAttributes) {
      logger.emit(.debug, "Attribute set to index: \(debugJson)")
    }
    
    
    itemAttributes.domainIdentifier = domainIdentifier
    
    // TODO: Why? What does this do?
    // itemAttributes.containerTitle = "TagProfile: \(userProfileId)"
    // itemAttributes.containerIdentifier = userProfileId
    
    
    return CSSearchableItem(
      uniqueIdentifier: "\(item.id)", domainIdentifier: domainIdentifier, attributeSet: itemAttributes
    )
  }
  
  func indexItems(_ items: [any IndexableItem]) async throws {
    let itemsToIndex = items.map(prepareItemForIndex)
    
    
    // Used for resuming from a crash; not currently used
    let clientData = Data()
    
    guard CSSearchableIndex.isIndexingAvailable() else {
      logger.emit(.error, "Indexing not available")
      return
    }
    
    secureIndex.beginBatch()
    
    do {
      try await secureIndex.indexSearchableItems(itemsToIndex)
      try await secureIndex.endBatch(withClientState: clientData);
    } catch {
      let clientData = String(data: clientData, encoding: .utf8) ?? "nil"
      
      self.logger.emit(.error, ErrorMsg("Error indexing items", error))
      self.logger.emit(.debug, "Client data: \(clientData)")
      
      return
    }
    
    let itemsList = itemsToIndex.map(\.uniqueIdentifier).joined(separator: "\n")
    
    logger.emit(.info, "Updated index '\(indexName)' with items:\n \(itemsList)")
  }
  
  func deleteItem(_ identifier: String) async throws {
    try await secureIndex.deleteSearchableItems(withIdentifiers: [identifier])
  }
  
  func deleteItems(_ contentIds: [ContentId]) async throws {
    try await secureIndex.deleteSearchableItems(withIdentifiers: contentIds.map(\.value))
  }
  
  func deleteAllItems() async throws {
    try await secureIndex.deleteAllSearchableItems()
  }

  func deleteAllitems(inDomain domainIdentifier: String) async throws {
    try await secureIndex.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
  }

  // TODO: FIgure out later
  func awaitQueryResponses(_ query: CSUserQuery) {
    self.searchState = .searching
    self.resultItems.removeAll()
    self.resultSuggestions.removeAll()
    
    Task {
      defer {
        self.logger.emit(.debug, "Query completed")
        self.searchState = .returned(results: self.resultItems)
      }
      
      do {
        for try await element in query.responses {
          switch(element) {
          case .item(let item):
            self.resultItems.append(item.item)
            break
          case .suggestion(let suggestion):
            self.resultSuggestions.append(suggestion.suggestion)
            break
          @unknown default:
            break
          }
        }
      } catch {
        self.onError(error)
      }
    }
  }
}
