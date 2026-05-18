// created on 11/28/25 by robinsr

import SwiftUI

struct KeyBindingsScreen: Scene {
  static let screenId = "\(Constants.appname).KeyBindings"
  static let screenSize = KeyBindingsTable.presentation.idealSize
  
  @Environment(\.dismissWindow) var dismissWindow
  
  @FocusState private var focuser: Bool
  
  var body: some Scene {
    UtilityWindow("Key Bindings", id: Self.screenId) {
      KeyBindingsTable()
//        .focusable()
//        .focusEffectDisabled()
//        .focused($focuser, equals: true)
        .buttonShortcut(key: .escape) {
          dismissWindow(id: Self.screenId)
        }
        .defaultFocus($focuser, true, priority: .userInitiated)
        .minimumSize(KeyBindingsTable.presentation.idealSize)
    }
    .windowResizability(.contentSize)
    .windowStyle(.titleBar)
    .defaultSize(KeyBindingsTable.presentation.idealSize)
    .commandsRemoved()
  }
}
