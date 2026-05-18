// created on 11/8/24 by robinsr

import SwiftUI

struct KeyboardKey: View {
  @Environment(\.dynamicTypeSize) var typeSize
  
  var text: String
  
  init(symbol: String) {
    self.text = symbol
  }
  
  init(key: KeyEquivalent) {
    self.text = key.asSymbol
  }

  var body: some View {
    ZStack {
      Text(verbatim: text)
        .foregroundColor(.primary)
    }
    .padding(4)
    .background {
      KeyBackground
    }
    .frame(width: 22)
  }
  
  var KeyBackground: some View {
    Rectangle()
      .fill(.primary.opacity(0.1))
      .aspectRatio(1.0, contentMode: .fit)
      .frame(width: 20, height: 20, alignment: .center)
      .border(.primary.opacity(0.5), width: 1.0, cornerRadius: 2)
      .shadow(color: .primary.opacity(0.5), radius: 0, x: 0.1, y: 0.1)
      .opacity(0.5)
  }
}


#Preview("KeyboardKey", traits: .fixedLayout(width: 680, height: 200)) {
  
  @Previewable @State var modKeys: [[EventModifiers]] = [
    [.command], [.control], [.option], [.shift]
  ]
  
  Grid(horizontalSpacing: 4.0) {
    GridRow {
      ForEach(modKeys.indexed, id: \.0) { index, key in
        KeyboardKey(symbol: key.first!.asSymbol)
      }
    }
    
    GridRow {
      ForEach(KeyEquivalent.numeric, id: \.self) { key in
        KeyboardKey(key: key)
      }
    }
    
    GridRow {
      ForEach(KeyEquivalent.punctuation, id: \.self) { key in
        KeyboardKey(key: key)
      }
    }
  }
  .padding()
}
