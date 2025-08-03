// created on 9/15/24 by robinsr

import Foundation
import CryptoKit
import SwifterSwift


extension String {
  static func md5(for text: String, withLength length: Int = 32) -> String {
    let hashedData = Insecure.MD5.hash(data: Data(text.utf8))
    return hashedData.map {
          // what the format means: % indicates start of format specifier
          // 0 specifies that the output should padded with zeros instead of spaces
          // 2 specifies that minimum width of output.
          //    - if less than 2 characters it will be padded with zeros to ensure at least two characters
          // x specifies that interget should be formatted as hexadecimal number using lowercase letters a-f
      String(format: "%02x", $0 )
    }
    .joined()
    .truncated(toLength: length)
  }
}

extension Array where Element == Character {
  func joined(separator: String = "") -> String {
    self.map{ $0.description }.joined(separator: separator)
  }
}
