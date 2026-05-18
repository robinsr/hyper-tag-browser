// created on 2/22/25 by robinsr

import Foundation


/**
 Represents the set of content items that a given action should be applied to.
 */
enum ContentScope: Equatable, Hashable, CustomStringConvertible {
  
    /// Applies to all content
  case global
  
    /// Applies to a single content item
  case only(ContentId)
  
    /// Applies to the specified items
  case include([ContentId])
  
    /// Applies to the specified items
  case set(of: Set<ContentId>)
  
    /// Applies to all but the specified items
  case exclude([ContentId])
  
    /// Applies to items matching parameters
  case matching(IndxRequestParams)
  
    /// Applies to the item with the corresponding fileURL (if exists)
  case atURL(URL)
  
  
  var rawValue: String {
    self.caseType.rawValue
  }
  
  var description: String {
    "\(rawValue)[\(ids)]"
  }
  
  var ids: [ContentId] {
    switch self {
    case .only(let id):
      return [id]
    case .include(let ids), .exclude(let ids):
      return ids
    case .set(let items):
      return items.asArray
    default:
      return []
    }
  }
  
  var isGlobal: Bool {
    if case .global = self { return true }
    return false
  }
  
  var parameters: IndxRequestParams? {
    if case .matching(let params) = self {
      return params
    }
    return nil
  }
  
  var url: URL? {
    if case .atURL(let url) = self {
      return url
    }
    return nil
  }
  
  var caseType: Cases {
    switch self {
    case .global: return .global
    case .only: return .only
    case .set: return .set
    case .include: return .include
    case .exclude: return .exclude
    case .matching: return .matching
    case .atURL: return .atURL
    }
  }
  
  enum Cases: String, CaseIterable {
    case global
    case only
    case include
    case set
    case exclude
    case matching
    case atURL
  }
}
