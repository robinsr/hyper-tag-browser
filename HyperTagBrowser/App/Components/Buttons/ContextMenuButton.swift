// created on 1/19/25 by robinsr

import SwiftUI


struct ContextMenuButton: View {
  let title: String
  let icon: String?
  let color: Color
  let action: () -> Void
  
  init(_ title: String, _ icon: String? = nil, _ color: Color = .primary, action: @escaping () -> Void) {
    self.title = title
    self.icon = icon
    self.color = color
    self.action = action
  }
  
  init(_ item: MenuActionable, _ color: Color = .primary, action: @escaping () -> Void) {
    self.init(item.label, item.icon, color, action: action)
  }
  
  init(_ title: String, _ icon: SymbolIcon, _ color: Color = .primary, action: @escaping () -> Void) {
    self.title = title
    self.icon = icon.systemName
    self.color = color
    self.action = action
  }
  
  var body: some View {
    Button {
      action()
    } label: {
      if let icon = icon {
        ContextMenuLabel(title, icon, color)
      } else {
        Text(verbatim: title)
      }
    }
  }
}

struct ContextMenuLabel: View {
  @Environment(\.showContextMenuSymbols) var useSymbols
  
  let title: String
  let symbolName: String?
  let symbolColor: Color
  
  init(_ title: String, _ icon: String? = nil, _ color: Color = .primary) {
    self.title = title
    self.symbolName = icon
    self.symbolColor = color
  }
  
  init(_ item: MenuActionable, _ color: Color = .primary) {
    self.init(item.label, item.icon, color)
  }
  
  var body: some View {
    HStack {
      if useSymbols, let icon = symbolName, !icon.isEmpty {
        Image(systemName: icon)
          .foregroundStyle(symbolColor)
      }
      
      Text(verbatim: title)
    }
  }
}

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


extension EnvironmentValues {
  @Entry var showContextMenuSymbols = true
}

extension View {
  func contextMenuSymbols(enabled showSymbols: Bool = true) -> some View {
    environment(\.showContextMenuSymbols, showSymbols)
  }
}
