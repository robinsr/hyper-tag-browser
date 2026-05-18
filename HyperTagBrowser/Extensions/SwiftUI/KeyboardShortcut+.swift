// created on 11/8/24 by robinsr

import SwiftUI


extension KeyboardShortcut {
  init(_ key: KeyEquivalent) {
    self.init(key, modifiers: [])
  }
}


extension KeyboardShortcut: @retroactive CustomStringConvertible {
  public var description: String {
    let modString = modifiers.asSymbols.joined()
    let keyString = key.asSymbol
    
    return "\(modString)+\(keyString)"
  }
}


extension KeyboardShortcut: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    let modString = modifiers.asSymbols.joined()
    let keyString = key.asSymbol
    
    return "KeyboardShortcut(key=\(keyString), modifiers=\(modString))"
  }
}
