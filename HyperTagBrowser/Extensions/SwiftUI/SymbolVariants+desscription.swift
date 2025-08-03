// created on 11/8/24 by robinsr

import SwiftUI

extension SymbolVariants {
  
  var symbolName: String {
    switch self {
    case .circle: return "circle"
    case .square: return "square"
    case .fill: return "fill"
    case .slash: return "slash"
    default: return ""
    }
  }
  
  var asModString: String {
    let allVariants: [SymbolVariants] = [.circle, .fill, .rectangle, .slash, .square]
    
    return allVariants
      .filter { self.contains($0) }
      .map { $0.symbolName }
      .joined(separator: ".")
  }
}
