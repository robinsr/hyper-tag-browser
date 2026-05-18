// created on 5/12/25 by robinsr

import Factory
import SwiftUI


struct ToggleSheetAction: ActionableCommand {
  @InjectedObservable(\Container.appViewModel) var appVM
  @Injected(\Container.dispatcher) var dispatch
  
  let sheet: AppSheet
  nonisolated let id: String
  
  init(sheet: AppSheet) {
    self.sheet = sheet
    self.id = sheet.id
  }
  
  var title: String { sheet._case.title }
  
  var isShowing: Bool {
    appVM.activeSheet?.id == sheet.id
  }
  
  var menuItemTitle: String? {
    isShowing ? "Hide \(title)" : "Show \(title)"
  }

  var shortcut: KeyBinding? {
    sheet._case.shortcut(isShowing: isShowing)
  }

  func perform(app: AppViewModel) {
    dispatch(.showSheet(isShowing ? .none : sheet))
  }
}
