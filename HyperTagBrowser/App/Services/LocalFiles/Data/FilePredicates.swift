// created on 10/14/24 by robinsr

import Foundation


typealias FilePredicate = (URL) -> Bool


/**
 * A collection of URL-based predicates
 */
struct FSPredicates {
  
  static var isHomeDir: FilePredicate {
    { url in url.isDirectory && url == .homeDirectory }
  }
  
  static var isAboveHomeDir: FilePredicate {
    { url in url.isDirectory && url.isParent(of: .homeDirectory) }
  }
}


extension URL {
  
  /**
   * Returns true if the URL matches the predicate
   */
  func conforms(to predicate: FilePredicate) -> Bool {
    return predicate(self)
  }
}
