// created on 11/24/25 by robinsr

import Factory
import Foundation


extension AppViewModel {
  
    // MARK: - UI Messaging Actions Impl
  
  func doClearMessage(_ message: AppMessage) {
    messages.unsend(message)

    if message.level == .restart {
      messages.send("Restarting app...")
      
      Task {
        try? await Task.sleep(for: .milliseconds(400))
        self.restart()
      }
    }
  }
    
    // MARK: - Configuring UI Actions Impl
  
  func doShowSheet(_ sheet: AppSheet) {
    switch sheet {
      case .none:
        activeSheet = nil
      default:
        activeSheet = sheet
    }
  }
  
  func doShowPanel(_ panel: AppPanels) {
    let dispatch = Container.shared.dispatcher()
    
    if !activeAppPanels.contains(panel) {
      dispatch(.togglePanel(panel))
    } else {
      logger.emit(.warning, "Panel \(panel.title.quoted) already showing")
    }
  }
  
  func doHidePanel(_ panel: AppPanels) {
    if activeAppPanels.contains(panel) {
      activeAppPanels.remove(panel)
    } else {
      logger.emit(.warning, "Panel \(panel.title.quoted) not found in active panels")
    }
  }
  
  func doTogglePanel(_ panel: AppPanels) {
    let panelShowing = activeAppPanels.contains(panel)

    if let parent = panel.parent {
      let situation = (activeAppPanels.contains(parent), panelShowing)

      switch situation {
        case (true, true):
          // parent+sub-panel showing, hide sub-panel
          activeAppPanels.remove(panel)
        case (true, false):
          // parent showing, not sub-panel, show sub-panel
          activeAppPanels.insert(panel)
        case (false, true):
          // parent hidden, sub-panel showing, show parent
          activeAppPanels.insert(parent)
        case (false, false):
          // parent hidden, sub-panel hidden, show both
          activeAppPanels.insert(parent)
          activeAppPanels.insert(panel)
      }
      return
    } else {
      // Regular toggling logic
      activeAppPanels.toggleExistence(panel)
    }
  }
}
