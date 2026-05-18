// created on 11/28/25 by robinsr

import SwiftUI

struct KeyBindingsTableRow: View {
  let binding: KeyBinding
  
  var body: some View {
    Grid(horizontalSpacing: 2.0) {
      GridRow {
        ForEach(binding.mods.asSymbols, id: \.self) { mod in
          KeyboardKey(symbol: mod)
        }
        KeyboardKey(key: binding.key)
      }
    }
  }
}

#Preview("KeyBindingsTableRow", traits: .fixedLayout(width: 300, height: 120)) {
  KeyBindingsTableRow(binding: .showPreferences)
    .padding()
}
