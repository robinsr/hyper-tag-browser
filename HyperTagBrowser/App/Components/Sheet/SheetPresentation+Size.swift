// created on 11/29/25 by robinsr

import Percentage
import SwiftUI

extension SheetPresentation {
  
  /**
   * Defines a set of options for configuring a Sheet's sizing properties
   * on the vertical or horizontal axis
   */
  public enum Size : Sendable, Hashable {
    /// A percentage of the ideal size to use as min/max values on this axis
    case flexible(Percentage)
      
    /// Specifies the lower limit the sheet can shrink to on this axis
    case min(CGFloat)
    
    /// Specifies the upper limit the sheet can expand to on this axis
    case max(CGFloat)
    
    /// The sheet will use the ideal size as a fixed size
    case fixed
    
    /// The sheet will be fitted to it's content.
    /// (On macos, `.fitted` is user-resizable)
    case fitted
    
    /// The sheet will be "sticky" (growing, but not shrinking) along the specified axis
    case sticky
    
    /// The sheet will be padded by the spcified amount
//    case pad(CGFloat)
    
    /// A specific fixed size derived from the ideal size and an additional amount
    case idealPlus(CGFloat)
    
    /// A specific fixed size derived from the ideal size minus some amount
    case idealMinus(CGFloat)
  }
  
}

extension Set where Element == SheetPresentation.Size {
  
  private var isSticky: Bool {
    self.contains(.sticky)
  }
  
  private var isFitted: Bool {
    self.contains(.fitted)
  }
  
  private var isFixed: Bool {
    self.contains(.fixed)
  }

  private var minSize: CGFloat? {
    self.reduce(nil as CGFloat?) { result, option in
      switch option {
        case .min(let min): result.map { Swift.min($0, min) } ?? min
        default: result
      }
    }
  }

  private var maxSize: CGFloat? {
    self.reduce(nil as CGFloat?) { result, option in
      switch option {
        case .max(let max): result.map { Swift.max($0, max) } ?? max
        default: result
      }
    }
  }
  
  private var percentGive: Percentage? {
    self.reduce(nil as Percentage?) { result, option in
      switch option {
        case .flexible(let percent): percent
        default: result
      }
    }
  }
  
  func maxSize(from ideal: CGFloat) -> CGFloat {
    if let maxSize = self.maxSize {
      return maxSize
    }
    
    if let percent = self.percentGive {
      return ideal + percent.of(ideal)
    }
    
    let additionalSize = self.reduce(0) { result, option in
      switch option {
      case .idealPlus(let additional): result + additional
      default: result
      }
    }
    
    return ideal + additionalSize
  }
  
  func minSize(from ideal: CGFloat) -> CGFloat {
    
    /// When `.sticky`, the sheet will not shrink from it's idealSize. When attempting to set
    /// a size less than the ideal size, the sheet will quickly and awkwardly bounces back to ideal
    guard !isSticky else {
      return ideal - 1.0
    }
    
    if let minSize = self.minSize {
      return minSize
    }
    
    if let percent = self.percentGive {
      return ideal - percent.of(ideal)
    }
    
    let subtractingSize = self.reduce(0) { result, option in
      switch option {
      case .idealMinus(let additional): result + additional
      default: result
      }
    }
    
    return ideal - subtractingSize
  }
  
//  @available(*, deprecated, message: "Approach doesn't support 4 sides of padding. Finding another way...")
//  var padding: CGFloat {
//    self.reduce(0) { result, option in
//      switch option {
//        case .pad(let pad): result + pad
//        default: result
//      }
//    }
//  }
}


extension Percentage: @unchecked @retroactive Sendable {}
