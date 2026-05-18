// created on 5/9/25 by robinsr

import Factory
import SwiftUI


/**
 * `PreviewModifier` to set `AppViewModel` into `@Environment`
 *
 * Usage:
 *
 * ```swift
 * #Preview("Wide Image Detail", traits: .defaultViewModel) {
 *    @Previewable @Environment(AppViewModel.self) var appVM
 *    MyComponent()
 * }
 * ```
 */
struct AppViewModelPreviewMod: PreviewModifier {
  typealias Context = (AppViewModel, GRDBIndexService)
  
  static func makeSharedContext() async -> Context {
    // let (indexer, _) = try! await InMemoryFixtureDB.setupDB([])
    // IndexerContainer.shared.dbURL.register { TestData.dbFile }
    // IndexerContainer.shared.indexService.register { indexer }
    
    FactoryContext.current.isPreview = true
    EnvContainer.shared.reset(options: .context)
    
    let indexer = IndexerContainer.shared.indexService()
    let app = Container.shared.appViewModel()
    let dsp = Container.shared.dispatcher()
    
    dsp.navigate(Route.folder(TestData.testImageDir))
    
    Task {
      app.contentItems = try! await indexer.getContentItems(matching: app.dbIndexParameters)
    }
    
    
    return (app, indexer)
  }

  func body(content: Content, context: Context) -> some View {
    EnvContainer.shared.autoRegister()
    
    let appVM = context.0
//    let indexService = context.1

    return
      content
        .environment(appVM)
        .environment(\.cursorState, CursorState())
        .environment(\.dbContentItems, appVM.contentItems)
        .environment(\.dbContentItemsVisible, appVM.contentItems)
        .environment(\.dbContentItemCount, appVM.contentItems.count)
        .environment(\.dbContentItemsHiddenCount, 0)
        .environment(\.dbContentItemsMissingCount, 0)
    
//    Other BrowseEnvironment Environment Keys
    
//        .environment(\.location, appVM.currentURL)
//        .environment(\.route, appVM.currentRoute)
//        .environment(\.page, appVM.currentPage)
//        .environment(\.appPanels, appVM.activeAppPanels)
//        .environment(\.currentSheet, appVM.activeSheet)
//        .environment(\.dbContentItems, appVM.contentItems)
//        .environment(\.dbContentItemsVisible, visibleItems)
//        .environment(\.dbContentItemsHiddenCount, hiddenItemCount)
//        .environment(\.dbContentItemsMissingCount, missingItemsCount)
//        .environment(\.dbContentItemCount, dbIndexCount)
//        .environment(\.dbContentItemParameters, appVM.dbIndexParameters)
//        .environment(\.parameters, appVM.dbIndexParameters)
//        .environment(\.queryResultCount, dbIndexCount)
//        .environment(\.dbItemDetail, dbItemDetail)
//        .environment(\.dbLocations, dbLocations)
//        .environment(\.dbQueues, dbQueues)
//        .environment(\.dbBookmarks, dbBookmarks)
  }
}


extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var defaultViewModel: Self = .modifier(AppViewModelPreviewMod())
  @MainActor static var app: Self = .modifier(AppViewModelPreviewMod())
}



fileprivate struct AppViewModelPropertiesView: View {
  @Environment(AppViewModel.self) var appVM
  
  var allProperties: [String:String] {
    [
      "_stageId"          : EnvContainer.shared.stage().id,
      "databasePath"      : IndexerContainer.shared.dbPath(),
      "location"          : appVM.currentPath.string,
      "profile id"        : appVM.currentProfile.id,
      "profile name"      : appVM.currentProfile.name,
      "profile suiteName" : appVM.currentProfile.suiteName,
    ]
  }
  
  var body: some View {
    List {
      ForEach(allProperties.sorted(by: <), id: \.key) { key, value in
        LabeledContent {
          Text(value)
        } label: {
          Text(key).monospaced().kerning(-0.5)
        }
      }
    }
  }
}



#Preview("AppViewModelPreviewMod", traits: .defaultViewModel, .fixedLayout(width: 400, height: 600)) {
  @Previewable @Environment(AppViewModel.self) var appVM
  
  AppViewModelPropertiesView()
    .frame(width: 400, height: 600, alignment: .topLeading)
}
