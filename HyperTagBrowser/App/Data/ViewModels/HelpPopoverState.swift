// created on 6/7/25 by robinsr

import SwiftUI

extension EnvironmentValues {
  @Entry var helpPopover = HelpPopoverState()
}


@Observable
final class HelpPopoverState {
  typealias Tip = any PreferenceTip
  typealias DismissFn = () -> Void

  init() {}

  private(set) var showing: String? = nil

  func showHelp(for pref: Tip) {
    showing = pref.id
  }

  func dismissHelp(for pref: Tip) {
    if pref.id == showing {
      showing = nil
    }
  }
}
