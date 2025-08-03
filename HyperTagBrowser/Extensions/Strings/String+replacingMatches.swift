// created on 4/8/25 by robinsr

import Foundation

extension String {
  func replacingMatches(
    of pattern: String,
    options: NSRegularExpression.Options = [],
    matchingOptions: NSRegularExpression.MatchingOptions = [],
    _ transform: (NSTextCheckingResult, String) -> String
  ) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
      return self
    }

    let nsrange = NSRange(self.startIndex..., in: self)
    var result = self
    var offset = 0

    regex.enumerateMatches(in: self, options: matchingOptions, range: nsrange) { match, _, _ in
      guard let match = match else { return }

      let matchRange = match.range
      let adjustedRange = NSRange(location: matchRange.location + offset, length: matchRange.length)

      let original = (result as NSString).substring(with: adjustedRange)
      let replacement = transform(match, original)

      result = (result as NSString).replacingCharacters(in: adjustedRange, with: replacement)
      offset += replacement.utf16.count - matchRange.length
    }

    return result
  }
}
