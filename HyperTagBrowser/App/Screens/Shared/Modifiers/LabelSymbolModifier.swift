// created on 4/18/25 by robinsr

import SwiftUI



struct LabelSymbolModifier: ViewModifier {
  @Environment(\.font) var font
  
  let symbol: SymbolIcon
  
  func body(content: Content) -> some View {
    HStack(alignment: .center, spacing: 3) {
      Image(symbol)
        .font(font)
      content
    }
  }
}


extension Text {
  func prefixWithSymbol(_ symbol: SymbolIcon) -> some View {
    modifier(LabelSymbolModifier(symbol: symbol))
  }
}
