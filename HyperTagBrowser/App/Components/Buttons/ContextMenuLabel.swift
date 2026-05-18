// created on 11/27/25 by robinsr

import SwiftUI


/**
 * A standardized component to be used with SwiftUI `Button` ``SwiftUI/Button/init(_:using:label:)`` as
 * the View passed as `label`
 */
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
