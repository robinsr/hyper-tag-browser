// created on 11/25/25 by robinsr

import SwiftUI

struct DividedViewModifier: ViewModifier {
  
  let edge: Edge
  let padding: EdgeInsets
  
  func body(content: Content) -> some View {
    switch (edge) {
    case .bottom:
      VStack {
        content
        Divider().padding(padding)
      }
    case .top:
      VStack {
        Divider().padding(padding)
        content
      }
    case .leading:
      HStack {
        Divider().padding(padding)
        content
      }
    case .trailing:
      HStack {
        content
        Divider().padding(padding)
      }
    }
    
  }
}

extension View {
  func divided(_ edge: Edge = .bottom, padding: EdgeInsets = .zero) -> some View {
    modifier(DividedViewModifier(
      edge: edge,
      padding: padding
    ))
  }
}
