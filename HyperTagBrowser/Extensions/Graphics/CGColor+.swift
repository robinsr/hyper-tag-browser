// created on 1/16/25 by robinsr

import AppKit
import CoreImage

extension CGColor {
  var asNSColor: NSColor {
    NSColor(cgColor: self) ?? NSColor.white
  }
  
  var hexString: String {
    [red, green, blue]
      .map { $0 * 255.99999 }
      .map { Int($0) }
      .map { String(format: "%02x", $0) }
      .joined()
  }
}
