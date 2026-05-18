// created on 9/28/24 by robinsr

import SwiftUI

extension EdgeInsets {
  
  /**
   * Creates a new `EdgeInsets`. Parameters mirror that of CSS margin/padding, starting
   * at the top and turning clockwise (top, left, bottom, right)
   */
  static func fromEdges(
    _ top: CGFloat = 0.0,
    _ trailing: CGFloat = 0.0,
    _ bottom: CGFloat = 0.0,
    _ leading: CGFloat = 0.0,
  ) -> EdgeInsets {
    EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
  }
  
  static func fromSides(horizontal: CGFloat, vertical: CGFloat) -> EdgeInsets {
    EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
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
  
  var inverse: EdgeInsets {
    EdgeInsets(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
  }
}
