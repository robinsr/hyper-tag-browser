// created on 2/7/25 by robinsr

import CoreSpotlight
import Factory
import System


struct SearchQuery: CustomStringConvertible {
  
  typealias ComparisonOperator = NSComparisonPredicate.Operator
  
  private let logger = EnvContainer.shared.logger("SearchQuery")
  private let indexName = Container.shared.spotlightServiceIndexName()
  private let domainId = Container.shared.spotlightDomainIdentifier()
  
  let queryString: String
  let searchTerms: [SearchTerm]
  let searchOptions: [UserSearchOption]
  let searchRoot: FilePath
  let searchSorting: SortType
  let searchTermOperator: PredicateCompoundType
  let paging: Paging
  
  init(
    queryString query: String = .random(ofLength: 30),
    options: [UserSearchOption] = [],
    location: FilePath = PreferencesContainer.shared.startingLocation(),
    sorting: SortType = .initial,
    joining compoundtype: PredicateCompoundType = .and,
    paging: Paging = .default
  ) {
    self.queryString = query
    self.searchOptions = options
    self.searchRoot = location
    self.searchSorting = sorting
    self.searchTermOperator = compoundtype
    self.paging = paging
    
    self.searchTerms = SearchTerm.Matcher
      .matchAll(in: query)
      .map { term, kind in
        SearchTerm(value: term, kind: kind)
      }
  }
  
  
  let defaultFetchAttributes = [
    "contentCreationDate",
    "contentModificationDate",
    "contentType",
    "contentURL",
    "displayName",
    "domainIdentifier",
    "fileType",
    "identifier",
    "keywords",
    "lastUsedDate",
    "thumbnailData",
    "title",
  ]
  
  var queryDomain: SearchQueryFragment {
    SearchQuery.Predicate(lhs: "domainIdentifier", rhs: domainId, compare: .equalTo)
  }
  
  var termPredicates: SearchQueryFragment {
    SearchQuery.Compound(opr: searchTermOperator, statements: searchTerms.map(\.searchPredicate))
  }
  
  var spotlightQuery: String {
    SearchQuery.Compound(opr: .and, statements: [queryDomain, termPredicates]).queryString
  }
  
  var searchContext: CSSearchQueryContext {
    let context = CSSearchQueryContext()
    context.fetchAttributes = defaultFetchAttributes
    return context
  }
  
  var userContext: CSUserQueryContext {
    let context = CSUserQueryContext()
    
    context.fetchAttributes = defaultFetchAttributes
    context.enableRankedResults = false
    context.disableSemanticSearch = true
    context.maxResultCount = 25
    context.maxRankedResultCount = 25
    
    searchOptions.forEach { flag in
      switch flag {
      case .rankedResults:
        context.enableRankedResults = true
      case .semanticSearch:
        context.disableSemanticSearch = false
      case .maxResults(let int):
        context.maxResultCount = int
      case .maxRanked(let int):
        context.maxRankedResultCount = int
      }
    }
    
    return context
  }
  
  var description: String {
    """
    SearchQuery(
      queryString: \(queryString),
      searchTerms: \(searchTerms.map(\.queryString).joined(separator: ", ")),
      searchOptions: \(searchOptions.map(\.description)),
      searchRoot: \(searchRoot.string),
      searchSorting: \(searchSorting.description),
      searchTermOperator: \(searchTermOperator.description),
      paging: \(paging.description),
      spotlightQuery: \(spotlightQuery)
    )
    """
  }
  
  
  public enum UserSearchOption: CustomStringConvertible, Codable, Hashable {
    case rankedResults
    case semanticSearch
    case maxResults(Int)
    case maxRanked(Int)
    
    static let `default`: [UserSearchOption] = [
      .rankedResults, .semanticSearch, .maxResults(10), .maxRanked(5)
    ]
    
    var description: String {
      switch self {
      case .rankedResults: "rankedResults"
      case .semanticSearch: "semanticSearch"
      case .maxResults(let int): "maxResults(\(int))"
      case .maxRanked(let int): "maxRanked(\(int))"
      }
    }
  }
  
  public struct Paging: CustomStringConvertible, Codable, Hashable {
    let pageNumber: Int
    let pageSize: Int
    
    init(pageNumber: Int = 0, pageSize: Int? = nil) {
      self.pageNumber = pageNumber
      self.pageSize = pageSize ?? Self.defaultPageSize
    }
    
    var offset: Int {
      pageNumber * pageSize
    }
    
    var description: String {
      "Paging(pageNumber: \(pageNumber), pageSize: \(pageSize))"
    }
    
    static var defaultPageSize: Int {
      PreferencesContainer.shared.userPreferences().forKey(.searchPerPageLimit)
    }
    
    static var test: Int {
      PreferencesContainer.shared.userProfile().suite[.searchPerPageLimit]
    }
    
    static var `default`: Paging {
      Paging(pageNumber: 0, pageSize: Self.defaultPageSize)
    }
  }
}

