// Created on 9/2/24 by robinsr

import Defaults
import Factory
import GRDBQuery
import LegibleError
import MacSettings
import OSLog
import SwiftUI


@available(macOS 15.0, *)
struct TaggedFileBrowserApp: App {
  
  private let logger = EnvContainer.shared.logger("App")
  
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  @Injected(\IndexerContainer.dbReader) var dbReader
  @Injected(\IndexerContainer.dbWriter) var dbWriter
  @Injected(\IndexerContainer.dbContext) var dbContext
  @Injected(\Container.appViewModel) var appVM
  @Injected(\Container.searchModel) var searchVM
  @Injected(\Container.messagesModel) var messages
  @Injected(\Container.dispatcher) var dispatcher
  @Injected(\Container.directoryTree) var dirTreeState
  @Injected(\Container.cursorState) var cursorState
  @Injected(\Container.detailViewModel) var detailState
  @Injected(\Container.colorModel) var colorModel
  
  @Injected(\PreferencesContainer.prefs) var userPrefs
  
  @Default(.devFlags) var devFlags: Set<DevFlags>
  
  init() {}
  
  func onDownloadsChanged(at url: URL) {
    logger.emit(.info, "Downloads folder changed")
  }
  
  var body: some Scene {
    Window(Constants.appDisplayName, id: "\(Constants.appDisplayName).Main") {
      MainScreen()
        .queryObservation(.always)
        .environment(\.queryObservationEnabled, true)
        .withUserColorScheme()
        .withWindowSizeEnvironment()
        .withModifierKeyObserver()
        .withBrowseEnv()
        .minimumSize(Constants.minWindowSize)
        .focusedValue(\.focusedViewModel, appVM)
        .focusedValue(\.activeAppSheet, appVM.activeSheet)
    }
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unifiedCompact)
    .windowResizability(.contentSize)
    .windowLevel(.normal)
    .defaultPosition(.center)
    .defaultSize(width: 800, height: 600)
    .commands {
      CommandsView()
    }
    .environment(appVM)
    .environment(searchVM)
    .environment(\.cursorState, cursorState)
    .environment(\.detailEnv, detailState)
    .environment(\.directoryTree, dirTreeState)
    .environment(\.enabledFlags, devFlags)
    .environment(\.location, appVM.currentURL)
    .environment(\.route, appVM.currentRoute)
    .environment(\.messages, messages.messageQueue)
    .environment(\.dispatcher) { action in
      dispatcher.dispatch(action)
    }
    .environment(\.pushState, { route in
      dispatcher.dispatch(.navigate(to: route, .push))
    })
    .environment(\.replaceState, { route in
      dispatcher.dispatch(.navigate(to: route, .replace))
    })
    .environment(\.popState, {
      dispatcher.dispatch(.popRoute)
    })
    .environment(\.notify, { msg in
      messages.send(msg)
    })
    .databaseContext(dbContext)
    
    KeyBindingsScreen()
      .environment(\.enabledFlags, devFlags)
    
    SettingsScreen()
      .environment(appVM)
      .environment(\.colorModel, colorModel)
      .environment(\.location, appVM.currentURL)
      .defaultSize(width: 480, height: 600)
  }
}
 

@main
struct MainEntryPoint {
  private static let logger = EnvContainer.shared.logger("App")
  
  static func main() {
    measurementEnabled = false
    
    EnvContainer.shared.reset(options: .context)
    
    if AppStage.isUnitTest {
      TestApp.main()
      return
    }

    let indexer = IndexerContainer.shared.indexService()
    
    do {
      try indexer.runMigrations()
      TaggedFileBrowserApp.main()
    } catch {
      fatalError("Failed to start app: \(error.legibleDescription)")
    }
  }
}


struct TestApp: App {
  var body: some Scene {
    WindowGroup {
    }
  }
}
