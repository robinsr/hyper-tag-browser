// created on 12/17/24 by robinsr

import Defaults
import Factory
import SwiftUI


struct BrowseScreenToolbar: View {
  @Environment(AppViewModel.self) var appVM
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.location) var location
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.colorModel) var bgColor
  
  var body: some View {
    Group {
      DebugTestAlertButton
        .debugVisible(flag: .views_debug)
      DebugDominantColorButton
        .debugVisible(flag: .views_debugDominantColor)
      DebugColorSchemeButtons
        .debugVisible(flag: .views_debugColorScheme)
      
        /// Increase/Decrease Tile Size (Slider)
      GridTileSizeSlider()
      
      ToolbarDivider()
      
      IndexFolderContentsButton
        .enabled(appVM.location.isIndexable)
      
      SearchFilesButton
      ToggleListModeButton
      OpenNewFolderButton
        
    }
    .buttonStyle(.toolbarIcon)
    .toggleStyle(.toolbar)
    
    ChangeSortTypeMenu
  }
  
    /// Index/Reindex Current Folder
  var IndexFolderContentsButton: some View {
    Button("Index Directory Contents", .database) {
      dispatch(.indexItems(inFolder: location))
    }
  }
  
    /// Search Files
  var SearchFilesButton: some View {
    Button("Search Files", .search) {
      dispatch(.showSheet(.searchSheet(query: "")))
    }
  }
  
    /// Toggle Recursive Subdirectories
  var ToggleListModeButton: some View {
    Toggle(isOn: .constant(appVM.listMode.type == .recursive)) {
      Button("Include subfolder contents", .subcontents) {
        dispatch(.setListMode(appVM.listMode.toggle))
      }
      .buttonStyle(.plain)
    }
  }
  
    /// Change Dir (Show File Dialog)
  var OpenNewFolderButton: some View {
    Button("Open Folder", .folder) {
      dispatch(.showSheet(.changeDirectory))
    }
  }
  
    /// Change Sort Dropdown
  var ChangeSortTypeMenu: some View {
    Menu {
      Picker(selection: Binding(
        get: { appVM.sorting },
        set: { dispatch(.setSortMode($0)) }
      )) {
        ForEach(SortType.allCases, id: \.id) { value in
          Text(value.description)
        }
      } label: {
        EmptyView()
      }
      .pickerStyle(.inline)
    } label: {
      Label("Sort By", .changeSort)
    }
    .menuStyle(.toolbar)
  }
  
  
  // MARK: Debug Buttons
  
  var DebugTestAlertButton: some View {
    Button("Test Alert Toast", .error) {
      let levels = AppMessage.Level.allCases.filter { $0 != .restart }
      
      dispatch(.notify(
        .init(TestData.LOREM, levels.randomElement()!)
      ))
    }
  }
  
  var DebugDominantColorButton: some View {
    ColorRect(color: bgColor.color)
      .help("Applied BG Color (@Environment)")
  }
  
  @ViewBuilder
  var DebugColorSchemeButtons: some View {
    ColorSchemeRect(bgColor.colorScheme)
      .help("ColorScheme derived from the applied BG color")
    
    ColorSchemeRect(colorScheme)
      .help("System Color Scheme")
  }
}


struct PresentationToggle: View {
  var presentation: BrowsePresentation
  @Binding var selection: BrowsePresentation
  
  var body: some View {
    Toggle(isOn: .equals($selection, eq: presentation)) {
      Button {
        selection = presentation.self
      } label: {
        Label(presentation.shortcut.description, presentation.icon)
          .padding(.leading, -2)
      }
      .buttonStyle(.plain)
      .keyboardShortcut(presentation.shortcut.keyboardShortcut)
    }
    .toggleStyle(.toolbar)
  }
}



