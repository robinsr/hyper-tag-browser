// Created on 9/15/24 by robinsr

import Cache
import Factory
import OSLog
import SwiftUI


extension Container {
  
  private var root: EnvContainer { .shared }
  private var prefs: PreferencesContainer { .shared }
  
  private var logger: CustomLogger {
    EnvContainer.shared.logger("Container")
  }
  
    // MARK: - View Models
  
  var appViewModel: Factory<AppViewModel> {
    self { @MainActor in
      AppViewModel()
    }
    .scope(.cached)
    .context(.test) { @MainActor in
      // TODO: Substitute with actual test instance for testing
      AppViewModel()
    }
  }
  
  var bookmarksStore: Factory<BookmarksStoreModel> {
    self { @MainActor in BookmarksStoreModel() }.scope(.singleton)
  }
  
  var dispatcher: Factory<AppDispatcher> {
    self { @MainActor in
      AppDispatcher()
    }
    .scope(.singleton)
  }
  
  var messagesModel: Factory<MessagesViewModel> {
    self { @MainActor in
      MessagesViewModel()
    }
    .scope(.singleton)
  }
  
  var messageQueue: Factory<AppMessageQueue> {
    self { @MainActor in
      self.messagesModel().messageQueue
    }
    .scope(.cached)
  }
  
  var cursorState: Factory<CursorState> {
    self {
      CursorState()
    }
    .scope(.cached)
  }
  
  var directoryTree: Factory<DirTreeModel> {
    self { @MainActor in
      DirTreeModel(cwd: self.prefs.startingLocation().fileURL)
    }
    .scope(.cached)
  }
  
  var detailViewModel: Factory<DetailScreenViewModel> {
    self { @MainActor in
      DetailScreenViewModel()
    }
    .scope(.cached)
  }
  
  var colorModel: Factory<DominantColorViewModel> {
    self {
      DominantColorViewModel()
    }
    .scope(.cached)
  }
  
  var searchModel: Factory<SearchModel> {
    self { @MainActor in
      SearchModel()
    }
    .scope(.singleton)
  }
  
  var windowObserver: Factory<WindowSizeObserver> {
    self {
      WindowSizeObserver()
    }
    .scope(.cached)
  }
      
    // -------------------------
    // MARK: - Search Properties
    // -------------------------
  
  var spotlightService: Factory<SpotlightSearchService> {
    self {
      SpotlightSearchService(
        indexName: self.spotlightServiceIndexName(),
        domainId: self.spotlightDomainIdentifier(),
        profileId: self.prefs.userProfileId()
      )
    }
    .scope(.cached)
  }
  
  var spotlightDomainIdentifier: Factory<String> {
    self {
      let stage = self.root.stage().id
      let profileId = self.prefs.userProfileId()
      
      return [stage, profileId].dotPath // eg "release.default" or "beta.testProfile1"
    }
    .onDebug {
      return "default"
    }
    .scope(.cached)
  }
  
  var spotlightServiceIndexName: Factory<String> {
    self {
      let stagedPath = self.root.stagedPath()
      let profileId = self.prefs.userProfileId()
      
      return [ stagedPath, profileId, "index" ].dotPath
    }
    .context(.arg("useDefaultSearchIndex")) {
      self.logger.emit(.debug, "Overriding spotlightServiceIndexName to 'default'")
      return "default"
    }
    .scope(.cached)
  }
  
    // MARK: - Services/Filesystem
  
  var metadataService: Factory<MetadataService> {
    self {
      MetadataService.shared
    }
    .scope(.cached)
  }
  
  var clipboardService: Factory<ClipboardService> {
    self {
      ClipboardService.shared
    }
    .scope(.cached)
  }
  
  var quicklookService: Factory<QuicklookService> {
    self {
      QuicklookService.shared
    }
    .scope(.cached)
  }
  
//  @MainActor
  var fileService: Factory<LocalFileService> {
    self { @MainActor in
      LocalFileService(monitoring: true)
    }
    .scope(.cached)
  }
  
  var fileCache: Factory<LocalFileCache> {
    self {
      LocalFileCache()
    }
    .scope(.cached)
  }
  
  var volumesService: Factory<VolumesService> {
    self {
      VolumesService()
    }
    .scope(.cached)
  }
  
  
    // MARK: - Other Properties
  
  var executor: Factory<CommandExecutor> {
    self { @MainActor in
      CommandExecutor()
    }
    .scope(.cached)
  }
  
  var colorTheme: Factory<ColorTheme> {
    self {
      MarianaTheme()
    }
    .scope(.cached)
  }
  
  var themeProvider: Factory<ThemeProvider> {
    self {
      ThemeProvider.shared
    }
    .scope(.cached)
  }
  
  //
  // MARK: - Metrics
  //
  
  var metricsRecorder: Factory<any MetricsRecorder> {
    self {
      NothingMetricsRecorder()
    }
    .context(.arg("emitMetrics")) {
      StdoutMetricsRecorder()
    }
    .scope(.cached)
  }
  
  var timer: Factory<SelfTimer> {
    self {
      SelfTimer()
    }
  }
}
