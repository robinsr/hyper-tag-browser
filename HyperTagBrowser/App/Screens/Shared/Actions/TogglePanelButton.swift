// created on 5/11/25 by robinsr

import Factory
import SwiftUI


struct TogglePanelAction: ActionableCommand {
  @InjectedObservable(\Container.appViewModel) private var appVM
  @Injected(\Container.dispatcher) var dispatch
  
  let panel: AppPanels
  nonisolated let id: String
  
  init(panel: AppPanels) {
    self.panel = panel
    self.id = "\(panel.rawValue)"
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
    dispatch(.togglePanel(panel))
  }
}
