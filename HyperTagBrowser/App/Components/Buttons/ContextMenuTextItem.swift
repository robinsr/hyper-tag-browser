// created on 11/27/25 by robinsr

import SwiftUI


/**
 * A non-clickable ``Button`` View adapted to just display text. Intended use is
 * embedding context-specific text info in a context menu
 */
struct ContextMenuTextItem: View {
  @Environment(\.showContextMenuSymbols) var useSymbols
  
  var text: String
  var symbol: String = ""
  
  init(_ text: String, _ symbol: String = "") {
    self.text = text
    self.symbol = symbol
  }
  
  var body: some View {
    Button {
      // no-op
    } label: {
      HStack {
        if useSymbols && !symbol.isEmpty {
          Image(systemName: symbol)
            .font(.caption)
        }
        
        Text(verbatim: text.uppercased())
          .font(.caption)
      }
    }
    .disabled(true)
  }
}
