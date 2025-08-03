// created on 9/28/24 by robinsr

import SwiftUI

extension EdgeInsets {
  static func fromEdges(_ tp: CGFloat = 0.0, _ ld: CGFloat = 0.0, _ bt: CGFloat = 0.0, _ tr: CGFloat = 0.0
  ) -> EdgeInsets {
    EdgeInsets(top: tp, leading: ld, bottom: bt, trailing: tr)
  }
  
  init(_ size: CGSize) {
    self.init(top: size.height, leading: size.width, bottom: size.height, trailing: size.width)
  }
  
  static func top(_ size: CGFloat) -> EdgeInsets {
    EdgeInsets(top: size, leading: 0, bottom: 0, trailing: 0)
  }
  
  static func leading(_ size: CGFloat) -> EdgeInsets {
    EdgeInsets(top: 0, leading: size, bottom: 0, trailing: 0)
  }
  
  static func bottom(_ size: CGFloat) -> EdgeInsets {
    EdgeInsets(top: 0, leading: 0, bottom: size, trailing: 0)
  }
  
  static func trailing(_ size: CGFloat) -> EdgeInsets {
    EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: size)
  }
  
  static var zero: EdgeInsets {
    EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
  }
}
