// created on 12/11/24 by robinsr

import Foundation
import AppKit


extension String {
  
  /**
   * Returns a width estimate for the string with the given font size.
   */
  func widthGuestimate(fontSize: CGFloat) -> CGFloat {
    let font = NSFont.systemFont(ofSize: fontSize)
    let attributes = [NSAttributedString.Key.font: font]
    let size = self.size(withAttributes: attributes)
    return size.width
  }
}
