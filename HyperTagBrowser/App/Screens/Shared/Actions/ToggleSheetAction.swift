// created on 5/12/25 by robinsr

import Factory
import SwiftUI


struct ToggleSheetAction: ActionableCommand {
  @Injected(\Container.appViewModel) private var appVM
  
  let sheet: AppSheet
  
  var id: String { sheet.id }
  var title: String { sheet._case.title }
  
  var isShowing: Bool {
    appVM.activeSheet?.id == sheet.id
  }

  var shortcut: KeyBinding? {
    sheet._case.shortcut(isShowing: isShowing)
  }
  
  var menuItemTitle: String? {
    shortcut?.description ?? title
  }

  func perform(app: AppViewModel) {
    appVM.dispatch(.showSheet(sheet))
  }
}
