// created on 1/19/25 by robinsr

import SwiftUI


/**
 * A standardized `Button`-based component to be used as buttons within ``SwiftUICore/View/contextMenu()``
 */
struct ContextMenuButton: View {
  let title: String
  let icon: String?
  let color: Color
  let action: () -> Void
  
  init(
    _ title: String, _ icon: String? = nil, _ color: Color = .primary, action: @escaping () -> Void
  ) {
    self.title = title
    self.icon = icon
    self.color = color
    self.action = action
  }
  
  
  init(
    _ title: String, _ icon: SymbolIcon, _ color: Color = .primary, action: @escaping () -> Void
  ) {
    self.title = title
    self.icon = icon.systemName
    self.color = color
    self.action = action
  }
  
    /// Create from context menu button from any ``MenuActionable`` (label:string,icon:string?)
  init(_ item: MenuActionable, _ color: Color = .primary, action: @escaping () -> Void) {
    self.init(item.label, item.icon, color, action: action)
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
