// created on 4/4/25 by robinsr

import SwiftUI


/**
 * Enum representing a rotational direction
 */
enum RotationalDirection: Double, CustomStringConvertible, CaseIterable {
  case clockwise, lefthanded
  case anticlockwise, righthanded
  
  var rawValue: Double {
    switch self {
    case .clockwise, .lefthanded:
      return 1.0
    case .anticlockwise, .righthanded:
      return -1.0
    }
  }
  
  var description: String {
    switch self {
    case .clockwise, .lefthanded: 
      return "Clockwise"
    case .anticlockwise, .righthanded:
      return "Anti-clockwise"
    }
  }
  
  var angle: CGFloat {
    CGFloat(self.rawValue)
  }
  
  var inverted: RotationalDirection {
    switch self {
    case .clockwise: .anticlockwise
    case .anticlockwise: .clockwise
    case .lefthanded: .righthanded
    case .righthanded: .lefthanded
    }
  }
  
  func apply(to angle: Angle) -> Angle {
    .degrees(angle.degrees * self.angle)
  }
  
  static var allCases: [RotationalDirection] {
    return [.clockwise, .anticlockwise]
  }
}
