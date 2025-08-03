// created on 9/7/24 by robinsr

import SwiftUI


/**
 * A protocol for defining app icons used in the application.
 */
protocol AppIcon {
  var systemName: String { get }
  var helpText: String? { get }
  var id: String { get }
}
