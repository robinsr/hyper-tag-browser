// created on 11/8/24 by robinsr

import SwiftUI


extension KeyboardShortcut {
  
  init(_ key: KeyEquivalent) {
    self.init(key, modifiers: [])
  }
  
  public var keys: [String] {
    (self.modifiers.asCharacters + [self.key.asCharacter]).map(\.description)
  }
}


extension KeyboardShortcut: @retroactive CustomStringConvertible {
  public var description: String {
    self.keys.joined()
  }
}


extension KeyboardShortcut: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    "KeyboardShortcut(keys=\(self.keys.joined()))"
  }
}
