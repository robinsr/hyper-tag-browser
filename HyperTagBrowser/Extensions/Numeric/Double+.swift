// created on 1/2/25 by robinsr

import Foundation


extension Double {
  func relativeDifference(to other: Double) -> Double {
    Swift.abs(self - other) / max(self, other)
  }
  
  func signedDifference(to other: Double) -> Double {
    self - other / max(self, other)
  }
  
  func minMax(_ min: Double, _ max: Double) -> Double {
    Swift.max(min, Swift.min(max, self))
  }
}
