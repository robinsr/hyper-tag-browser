// created on 2/7/25 by robinsr

import Defaults
import Factory


/**
 * Defines the methods/strategies available to search for content in app.
 *
 * Ideally this is under the hood, but it is exposed to the user for debugging purposes.
 *
 *
 * ## Issues
 *
 * ```log
 * # issue with search query - 2025-05-09
 * [QPNLU][qid=2] Error Domain=com.apple.SpotlightEmbedding.EmbeddingModelError Code=-8007 "Text embedding generation timeout (timeout=100ms)" UserInfo={NSLocalizedDescription=Text embedding generation timeout (timeout=100ms)}
 * [CSUserQuery][qid=2] got a nil / empty embedding data dictionary
 * ### qid=2 error Error Domain=CSSearchQueryErrorDomain Code=-2000 "(null)" reply:<xpc object>
 * qid=2 - Finished with error error:Error Domain=CSSearchQueryErrorDomain Code=-2000 "(null)"
 * ```
 */
enum SearchMethod: String, CaseIterable, Defaults.Serializable {
  
  case searchQuery = "Search Query"
  case userSearch = "User Search"
  case userQuery = "User Query"
  case databaseQuery = "Database Query"
  
  var disabled: Bool {
    let stage = EnvContainer.shared.stage()
    
    if stage.isProd {
      switch self {
      case .userSearch: return false
      default: return true
      }
    }
    
    return false
  }
}


extension SearchMethod: CustomStringConvertible, CustomDebugStringConvertible {
  var description: String {
    self.rawValue
  }
  
  var debugDescription: String {
    switch self {
    case .searchQuery: "SearchMethod.\(rawValue)(CSSearchQuery)"
    case .userSearch: "SearchMethod.\(rawValue)(CSUserQuery userQueryString/userQueryContext)"
    case .userQuery: "SearchMethod.\(rawValue)(CSUserQuery queryString/queryContext)"
    case .databaseQuery: "SearchMethod.\(rawValue)(GRDB Query)"
    }
  }
}


extension SearchMethod: SelectableOptions {
  static var asSelectables: [SelectOption<SearchMethod>] {
    allCases.map { SelectOption(value: $0, label: $0.rawValue, disabled: $0.disabled) }
  }
}
