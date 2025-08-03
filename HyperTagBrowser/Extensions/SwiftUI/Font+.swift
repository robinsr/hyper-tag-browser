// created on 6/4/25 by robinsr

import AppKit
import SwiftUI

extension Font {
  /// Returns a system font with the specified size and weight.

  /**
   * Returns a CGFloat representing the point size for the specified font style.
   *
   * References Human Interface Guidelines for font sizes:
   * https://developer.apple.com/design/human-interface-guidelines/typography#macOS-built-in-text-styles
   *
   * Alternatively, use `@ScaledMetric`:
   *
   * ```swift
   *   // Scales `paddingVertical` to (I believe) 10/13 of whatever `.body` is (13.0 being the default .body)
   * @ScaledMetric(relativeTo: .body) var paddingVertical = 10.0
   * ```
   */
  var nsPointSize: CGFloat {
    switch self {
      case .largeTitle:
        // largeTitle: Regular, Bold
        return 26.0
      case .title:
        // title: Regular, Bold
        return 22.0
      case .title2:
        // title2: Regular, Bold
        return 17.0
      case .title3:
        // title3: Regular, Semibold
        return 15.0
      case .headline:
        // headline: Bold, Heavy
        return 13.0
      case .body:
        // body: Regular, Semibold
        return 13.0
      case .callout:
        // callout: Regular, Semibold
        return 12.0
      case .subheadline:
        // subheadline:Regular, Semibold
        return 11.0
      case .footnote:
        // footnoote: Regular, Semibold
        return 10.0
      case .caption:
        // caption: Regular, Medium
        return 10.0
      case .caption2:
        // caption2: medium, Semibold
        return 10.0
      default:
        return NSFont.systemFontSize
    }
  }
}
