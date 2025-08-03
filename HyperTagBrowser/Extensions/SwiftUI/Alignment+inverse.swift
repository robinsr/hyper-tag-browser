// created on 12/17/24 by robinsr

import SwiftUI


extension Alignment {
  func inverse() -> Alignment {
    switch self {
    case .leading:
      return .trailing
    case .trailing:
      return .leading
    default:
      return .center
    }
  }
}
