// created on 11/24/25 by robinsr

import Defaults
import Factory
import Foundation


extension AppViewModel {
  
    // MARK: - Navigation Actions Imps
  
  func doNavigate(to route: Route, action: Route.Action = .push) {
    guard route != currentRoute else {
      return
    }

    switch action {
      case .push:
        logger.emit(.info.off, "Appending route: \(route)")

        navigationPath.append(route)
      case .replace:
        logger.emit(.info.off, "Replacing route: \(route)")

        if let last = navigationPath.last {
          navigationPath.replace(last, with: route)
        } else {
          navigationPath.append(route)
        }
    }
  }
  
  func doPopRoute() {
    if navigationPath.hasPrevious {
      navigationPath.removeLast()
    }
  }
  
  func handleDismissRequest() {
    let dispatch = Container.shared.dispatcher()

    // If a modal is showing, dismiss it, returning after the first UI change.
    if activeSheet != nil {
      dispatch(.showSheet(.none))
      return
    }

    // If a panel is showing, close it, returning after the first UI change.
    for panel in AppPanels.closePriority {
      if activeAppPanels.contains(panel) {
        dispatch(.hidePanel(panel))
        return
      }
    }
    
    // If no active modal or panel, and page is Detail then navigate back
    if case .content = currentPage {
      dispatch(.popRoute)
      return
    }
  }
}
