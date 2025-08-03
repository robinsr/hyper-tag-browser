// created on 5/15/25 by robinsr

import SwiftUI


enum WindowBreakpoint: Double {
  case small = 600.0
  case medium = 1200.0
  case large = 1600.0
  
  var approximateWindowSize: CGSize {
    CGSize(
      width: CGFloat(self.rawValue),
      height: CGFloat(self.rawValue * 9.0/16.0)
    )
  }
}


@Observable
final class WindowSizeObserver {
  var size = CGSize.zero
  var safeArea = EdgeInsets.fromEdges(0, 0, 0, 0)
  
  func divideForItems(ofWidth itemWidth: Double, spaced itemSpacing: Double) -> Double {
    let availableWidth = size.width - itemSpacing
    let perItemWidth = itemWidth + itemSpacing
    
    return floor(availableWidth/perItemWidth)
  }
  
  func upToBreakpoint(_ breakpoint: WindowBreakpoint) -> Bool {
    size.width.isWithinBreakpoint(breakpoint)
  }
  
  func betweenBreakpoints(_ lower: WindowBreakpoint, _ upper: WindowBreakpoint) -> Bool {
    size.width.isWithinBreakpoints(lower, upper)
  }
  
  func beyondBreakpoint(_ breakpoint: WindowBreakpoint) -> Bool {
    upToBreakpoint(breakpoint) == false
  }
}


extension CGFloat {
  func isWithinBreakpoint(_ breakpoint: WindowBreakpoint) -> Bool {
    self.isLess(than: breakpoint.rawValue)
  }
  
  func isWithinBreakpoints(_ lower: WindowBreakpoint, _ upper: WindowBreakpoint) -> Bool {
    self.isBetween(lower.rawValue...upper.rawValue)
  }
}

extension CGSize {
  static let largeWindow: CGSize = {
    WindowBreakpoint.large.approximateWindowSize
  }()
}
