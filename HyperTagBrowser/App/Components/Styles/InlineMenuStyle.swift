// created on 12/9/24 by robinsr

import SwiftUI


struct InlineMenuStyle : MenuStyle {
  @State var isHovered = false
  
  public func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .pointerStyle(.link)
      .buttonStyle(.inlineDropdown)
      .styleClass(.link(.bold))
  }
}


extension MenuStyle where Self == InlineMenuStyle {
  /// Applies menuStyle ``InlineMenuStyle``
  ///
  /// ```swift
  /// Menu(/*...*/).menuStyle(.inlineDropdown)
  /// ```
  static var inlineDropdown: Self { InlineMenuStyle() }
}
