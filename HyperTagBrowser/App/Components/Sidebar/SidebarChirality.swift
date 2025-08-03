// created on 3/31/25 by robinsr

import Defaults
import SwiftUI



enum SidebarChirality: String, Defaults.Serializable, CaseIterable, SelectableOptions {
  case left = "Left"
  case right = "Right"
  
  /**
   * The horizontal alignment of the Sidebar relative to the main content (.left = leading, .right = trailing)
   */
  var relativeAlignment: Alignment {
    switch self {
    case .left: .leading
    case .right: .trailing
    }
  }
  
  var relativeEdge: Edge.Set {
    switch self {
    case .left: .leading
    case .right: .trailing
    }
  }
  
  /**
   * The alignment of the Sidebar's child views
   */
  var contentAlignment: Alignment {
    switch self {
    case .left: .topTrailing
    case .right: .topLeading
    }
  }

  
  static var asSelectables: [SelectOption<Self>] {
    allCases.map {
      SelectOption(value: $0, label: $0.rawValue)
    }
  }
  
  static var minimumWidth: CGFloat { 200 }
  
  static var idealWidth: CGFloat { 300 }
  
  static var maximumWidth: CGFloat { 420 }
}
