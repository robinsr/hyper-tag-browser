// Created on 9/15/24 by robinsr

import SwiftUI
import Defaults
import Foundation
import CustomDump


struct HelpScreen: Scene {
  static let screenId = "\(Constants.appname).HelpScreen"
  
  @Environment(\.dismissWindow) var dismissWindow
  
  @FocusState private var focuser: Bool
  
  var body: some Scene {
    Window("Keybinds", id: HelpScreen.screenId) {
      KeyboardShortcutsView()
        .focusable()
        .focusEffectDisabled()
        .focused($focuser, equals: true)
        .buttonShortcut(shortcut: KeyboardShortcut(.escape)) {
          dismissWindow(id: HelpScreen.screenId)
        }
        .defaultFocus($focuser, true)
    }
    .windowResizability(.contentSize)
    .windowStyle(.hiddenTitleBar)
    .defaultSize(Constants.minWindowSize)
  }
}

struct KeyboardShortcutsView: View {
  @Environment(\.colorModel) var bgColor
  
  var body: some View {
    ScrollView {
      VStack {
        ShortcutsGridContent
          .modalContentSection()
      }
      .modalContentBody()
      .scenePadding()
    }
    .scrollIndicators(.never)
    .withUserPrefBackgroundColor()
    .colorScheme(bgColor.colorScheme)
  }
  
  var gridConfig: [GridItem] {
    // Array(repeating: .init(.flexible(minimum: 300, maximum: 450), alignment: .top), count: KeyBinding.groups.count / 2)
    Array(repeating: .init(.adaptive(minimum: 300, maximum: 450), alignment: .top), count: 1)
  }

  var ShortcutsGridContent: some View {
    LazyVGrid(columns: gridConfig, alignment: .center, spacing: 24) {
      ShortcutGroups
    }
  }
  
  var sortedGroups: [KeyBinding.Group] {
    KeyBinding.Group.allCases.sorted(by: \.members.count)
  }
  
  var ShortcutGroups: some View {
    ForEach(sortedGroups.indexed, id: \.1.id) { index, group in
      GroupBox {
        VStack(spacing: 0) {
          ForEach(group.members, id: \.id) { shortcut in
            ShortcutRow(shortcut)
          }
        }
      } label: {
        Text(group.name)
          .styleClass(.sectionLabel)
      }
      .frame(minWidth: 300)
    }
  }
  
  func ShortcutRow(_ shortcut: KeyBinding) -> some View {
    HStack {
      Text(.init(shortcut.description))
      
      Spacer()
      
      KeyboardBindingView(binding: shortcut)
    }
  }
}


struct KeyboardBindingView: View {
  let binding: KeyBinding
  
  var body: some View {
    HStack(spacing: 2) {
      ForEach(binding.mods.asCharacters, id: \.self) { mod in
        KeyboardKey(symbol: mod)
      }
      KeyboardKey(key: binding.key)
    }
    .padding(.horizontal, 2)
  }
}


#Preview("Help Screen", traits: .testBordersOn, .fixedLayout(width: 768, height: 510)) {
  KeyboardShortcutsView()
}
