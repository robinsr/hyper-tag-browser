// created on 11/22/24 by robinsr

import SwiftUI


enum PillButtonSize: String, CaseIterable, Identifiable, Hashable {
  case large
  case small
  
  var insets: EdgeInsets {
    switch self {
    case .small: return EdgeInsets.fromEdges(4, 7, 4, 7)
    case .large: return EdgeInsets.fromEdges(6, 12, 6, 12)
    }
  }
  
  var font: Font {
    switch self {
    case .small: return .callout.weight(.regular)
    case .large: return .body.weight(.regular)
    }
  }
  
  var id: String { self.rawValue }
}
