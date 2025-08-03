// created on 5/12/25 by robinsr

import Factory
import SwiftUI


struct ActionMenuButton<Command: ActionableCommand>: View {
  @Injected(\Container.appViewModel) private var appVM
  
  let command: Command

  var body: some View {
    Button(command.menuItemTitle ?? command.title) {
      command.perform(app: appVM)
    }
    .ifLet(command.shortcut) {$0
      .keyboardShortcut($1)
    }
  }
}
