// created on 1/7/25 by robinsr

import SwiftUI

struct KeyBindingIconLabel: View {
  let symbol: SymbolIcon
  let shortcut: KeyBinding?
  
  var body: some View {
    ZStack(alignment: .bottom) {
      Image(symbol)
        .foregroundStyle(.primary.opacity(0.2))
        .font(.system(size: 30))
      
      if let shortcut {
        HStack(alignment: .bottom, spacing: 0) {
          Text(shortcut.mods.asCharacters.joined(separator: " "))
          
          Text(String(shortcut.key.character))
            .font(.system(size: 16, weight: .semibold))
        }
        .italic()
        .foregroundStyle(.primary.opacity(0.8))
        .shadow(color: .secondary.opacity(0.5), radius: 1, x: 1, y: 1)
        .padding(.bottom, 2)
      }
    }
    .frame(width: 30, height: 30)
    .padding(2)
  }
}

