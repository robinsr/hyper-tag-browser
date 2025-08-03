// created on 11/22/24 by robinsr

import SwiftUI

struct UnderlineOnHoverModifier: ViewModifier {
  @State private var isHovered = false
  
  func body(content: Content) -> some View {
    content
      .underline(self.isHovered)
      .onHover { inside in
        self.isHovered = inside
      }
    }
}
