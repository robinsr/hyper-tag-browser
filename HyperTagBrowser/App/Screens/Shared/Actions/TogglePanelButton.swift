// created on 5/11/25 by robinsr

import Factory
import SwiftUI


struct TogglePanelAction: ActionableCommand {
  @Injected(\Container.appViewModel) private var appVM
  
  let panel: AppPanels
  
  var id: String {
    "\(panel.rawValue)"
  }
  
  var title: String {
    "Toggle \(panel.title)"
  }

  var menuItemTitle: String? {
    appVM.activeAppPanels.contains(panel) ? "Hide \(panel.title)" : "Show \(panel.title)"
  }

  var shortcut: KeyBinding? {
    panel.shortcut(isShowing: appVM.activeAppPanels.contains(panel))
  }

  func perform(app: AppViewModel) {
    appVM.dispatch(.togglePanel(panel))
  }
}
