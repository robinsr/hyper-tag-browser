// created on 4/30/25 by robinsr

import SwiftUI

struct InlineMenuButtonStyle : ButtonStyle {
  @State var isHovered = false
  
  public func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 3) {
      configuration.label
      Image(systemName: "chevron.down")
        .scaleEffect(0.8)
    }
    .buttonStyle(LinkButtonStyle())
  }
}

extension ButtonStyle where Self == InlineMenuButtonStyle {
  /// Applies buttonStyle ``InlineMenuButtonStyle``
  ///
  /// ```swift
  /// Menu(/*...*/).buttonStyle(.inlineDropdown)
  /// ```
  static var inlineDropdown: Self { InlineMenuButtonStyle() }
}
