// created on 9/17/24 by robinsr

import SwiftUI
import Factory
import Defaults
import UniformTypeIdentifiers


struct NavigationToolbarView: View {
  @Environment(AppViewModel.self) var appVM
  @Environment(\.dbBookmarks) var bookmarks
  @Environment(\.location) var location
  @Environment(\.dispatcher) var dispatch
  @Environment(\.pushState) var navigate
  @Environment(\.appPanels) var panels
  
  typealias Component = NavigationToolbarComponent
  
  var components: [Component] = []
  
  init(with components: [Component]) {
    self.components = components
  }
  
  func isBookmarked(_ url: URL) -> Bool {
    bookmarks.contains(where: { $0.filepath == url.filepath })
  }

  var body: some View {
    ForEach(components, id: \.self) { component in
      switch component {
      case .bookmarkLocation:
        AddBookmarkButton
      case .navigateBack:
        NavigateBackButton
      case .navigateUpDirectory:
        NavigateUpButton
      case .toggleSidebar:
        ToggleSidebarButton
      case .text(let text):
        Text(text)
          .styleClass(.sectionLabel)
      }
    }
  }
  
  var AddBookmarkButton: some View {
    Button(.bookmark) {
      if isBookmarked(location) {
        dispatch(.bookmarkCurrentLocation)
      } else {
        dispatch(.unbookmarkCurrentLocation)
      }
    }
    .buttonStyle(.toolbarIcon)
  }
  
  var NavigateBackButton: some View {
    Button(.back) {
      dispatch(.popRoute)
    }
    .buttonStyle(.toolbarIcon)
  }
  
  var NavigateUpButton: some View {
    Button(.goUpDirectory) {
      navigate(.folder(location.filepath.directory))
    }
    .buttonStyle(.toolbarIcon)
  }
  
  var ToggleSidebarButton: some View {
    Toggle(isOn: appVM.bindToPanel(.sidebar)) {
      Label(.sidebar)
    }
    .toggleStyle(.toolbar)
  }
}

enum NavigationToolbarComponent: Hashable {
  case toggleSidebar
  case navigateBack
  case navigateUpDirectory
  case bookmarkLocation
  case text(String)
}

extension Collection where Element == NavigationToolbarComponent {
  
  /// List of toolbar components used on the Browse screen
  static var browseItems: [NavigationToolbarComponent] {
    [.toggleSidebar, .navigateBack, .navigateUpDirectory, .bookmarkLocation]
  }
  
  /// List of toolbar components used on the Detail/Content screen
  static var detailItems: [NavigationToolbarComponent] {
    [.navigateBack]
  }
}


#Preview("NavigationToolbarView", traits: .defaultViewModel) {
  @Previewable @Environment(AppViewModel.self) var app
  @Previewable @Default(.profileOpenTo) var home
  
  HStack(alignment: .top) {}
  .toolbar {
    ToolbarItemGroup(placement: .navigation) {
      NavigationToolbarView(with: [
        .text("Navigation Placement"),
        .navigateBack,
        .navigateUpDirectory
      ])
    }
    
    ToolbarItemGroup(placement: .accessoryBar(id: "detail-page-toolbar")) {
      NavigationToolbarView(with: [
        .text("Accessory Bar Placement"),
        .navigateBack,
        .navigateUpDirectory,
        .bookmarkLocation
      ])
    }
  }
  .withTestBorder()
  .frame(preset: .wide)
}


//struct LeftoversHistoryView: View {
//  var historyItems: [(Int, Route)] {
//    let startOffset = 1
//    let maxItems = 12
//
//    let history: [Route] = Array(appVM.navigationPath.reversed().dropFirst(startOffset))
//
//    return Array(zip(0...min(maxItems, history.count), history))
//  }
//
//  var HistoryMenuItems: some View {
//    ForEach(historyItems, id: \.0) { index, route in
//      Button(route.filepath) {
//        for _ in 0...index {
//          dispatch(.popRoute)
//        }
//      }
//    }
//  }
//}
