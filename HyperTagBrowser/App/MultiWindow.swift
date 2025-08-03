// created on 2/4/25 by robinsr

import SwiftUI
import Factory
import GRDBQuery

/**
 * Work in progress; not yet functional.
 */

@available(macOS 15.0, *)
struct MultiWinTaggedFileBrowserApp: App {
  
  @Injected(\IndexerContainer.indexService) var indexer
  @Injected(\IndexerContainer.dbReader) var dbReader
  @Injected(\IndexerContainer.dbWriter) var dbWriter
  @Injected(\IndexerContainer.databaseObserver) var dbObserver
  
  init() {
    self.dbObserver.startObservation()
  }
  
  var body: some Scene {
    WindowGroup {
      MultiWindowContentView(windowId: .randomIdentifier(24))
    }
    .windowStyle(.hiddenTitleBar)
    .windowToolbarStyle(.unifiedCompact)
    .windowResizability(.contentSize)
    .windowLevel(.normal)
    .defaultPosition(.center)
    .defaultSize(width: 800, height: 600)
  }
}


struct MultiWindowContentView: View {
  @Injected(\IndexerContainer.indexService) var indexer
  @Injected(\IndexerContainer.dbReader) var dbReader
  @Injected(\IndexerContainer.dbWriter) var dbWriter
  @Injected(\IndexerContainer.databaseObserver) var dbObserver
  
  @State var appVM = AppViewModel()
  @State var gridCursor = CursorState()
  
  var windowId: AppWindowInstance.ID
  
  
  var body: some View {
    ZStack {
      if let dbError = indexer.error {
        FatalErrorView(error: dbError)
      } else {
        MainScreen()
          .queryObservation(.always)
          .environment(\.queryObservationEnabled, true)
      }
    }
    .withWindowSizeEnvironment()
    .minimumSize(Constants.minWindowSize)
    .environment(appVM)
    .environment(gridCursor)
    .databaseContext(appVM.databaseContext)
    .navigationTitle(appVM.location.lastPathComponent)
  }
}

struct AppWindowInstance: Identifiable {
  var id: String = .randomIdentifier(24)
}
