// created on 4/2/25 by robinsr

import SwiftUI


extension Button where Label == SwiftUI.Label<Text, Image> {
  
    /// Creates a Button from a `SymbolIcon`
  init(_ symbol: SymbolIcon, action: @escaping () -> Void) {
    self.init(action: action, label: {
      Label(symbol)
    })
  }
    /// Creates a Button from a `SymbolIcon` and a custom title
  init(_ title: String, _ symbol: SymbolIcon, action: @escaping () -> Void) {
    self.init(action: action, label: {
      Label(title, symbol)
    })
  }
}
