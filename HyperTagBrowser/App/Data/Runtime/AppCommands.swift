// created on 5/8/25 by robinsr

import SwiftUI

@MainActor
protocol ActionableCommand: Identifiable, Sendable {
  var id: String { get }
  var title: String { get }
  var menuItemTitle: String? { get }
  var shortcut: KeyBinding? { get }
  
  func perform(app: AppViewModel) -> Void
}
