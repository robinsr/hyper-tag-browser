// Created on 9/15/24 by robinsr


import Factory
import OSLog
import SwiftUI


extension Container {
  
  private var root: EnvContainer { .shared }
  private var prefs: PreferencesContainer { .shared }
  
  private var logger: Logger {
    EnvContainer.shared.logger("Container")
  }
  
    // MARK: - View Models
  
  var appViewModel: Factory<AppViewModel> {
    self {
      AppViewModel()
    }
    .scope(.cached)
    .context(.test) {
      // TODO: Substitute with actual test instance for testing
      AppViewModel()
    }
  }
  
  var cursorState: Factory<CursorState> {
    self {
      CursorState()
    }
    .scope(.cached)
  }
  
  var thumbnailStore: Factory<ThumbnailStore> {
    self {
      ThumbnailStore()
    }
    .scope(.cached)
  }
  
  var directoryTree: Factory<DirTreeModel> {
    self {
      DirTreeModel(cwd: self.prefs.startingLocation().fileURL)
    }
    .scope(.cached)
  }
  
  var detailViewModel: Factory<DetailScreenViewModel> {
    self {
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
  
  var windowObserver: Factory<WindowSizeObserver> {
    self {
      WindowSizeObserver()
    }
    .scope(.cached)
  }
      
    // -------------------------
    // MARK: - Search Properties
    // -------------------------
  
  var spotlightService: Factory<SpotlightService> {
    self {
      SpotlightService()
    }
    .scope(.cached)
  }
  
  var spotlightDomainIdentifier: Factory<String> {
    self {
      let stage = self.root.stageId()
      let profileId = self.prefs.userProfileId()
      
      return [ stage, profileId ].dotPath
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
  
  var fileService: Factory<LocalFileService> {
    self {
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
  
  
    // MARK: - Other Properties
  
  var executor: Factory<CommandExecutor> {
    self {
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
  
  
    // MARK: - Metrics
  
  var metricsRecorder: Factory<any MetricsRecorder> {
    self {
      //NothingMetricsRecorder()
      StdoutMetricsRecorder()
    }
    .context(.test) {
      NothingMetricsRecorder()
    }
    .context(.debug) {
      GraphiteMetricsRecorder()
    }
    .scope(.cached)
  }
  
  var timer: Factory<SelfTimer> {
    self {
      SelfTimer()
    }
  }
}
