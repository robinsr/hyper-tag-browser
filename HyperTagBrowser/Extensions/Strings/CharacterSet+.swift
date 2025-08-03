// created on 2/21/25 by robinsr

import Foundation


extension CharacterSet {
  /// A character set containing the characters that are allowed in a valid
  /// identifier.
  static var validIdentifier: CharacterSet {
    CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
  }
  
  
  static var curlyBraces: CharacterSet {
    CharacterSet(charactersIn: "{}")
  }
}
