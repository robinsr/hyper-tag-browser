// created on 9/3/24 by robinsr


import SwiftUI
import Defaults
import Factory
import CustomDump


struct BrowseScreen: View {
  
  @Injected(\Container.executor) var exec
  @Injected(\IndexerContainer.indexService) var indexer
  @Injected(\PreferencesContainer.userProfileName) var profileName
  @Injected(\Container.themeProvider) var theme
  
  @Environment(AppViewModel.self) var appVM
  @Environment(\.isEnabled) var envIsEnabled
  @Environment(\.cursorState) var cursorState
  @Environment(\.modifierKeys) var modState
  @Environment(\.windowSize) var windowSize
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.enabledFlags) var devFlags
  
  @Environment(\.dispatcher) var dispatch
  
  @Environment(\.location) var location
  @Environment(\.appPanels) var panels
  @Environment(\.dbContentItemParameters) var query
  @Environment(\.dbContentItems) var dbContentItems
  @Environment(\.dbContentItemsVisible) var visibleItems
  @Environment(\.dbContentItemCount) var dbIndexCount
  @Environment(\.dbContentItemsHiddenCount) var hiddenItemCount
  @Environment(\.dbContentItemsMissingCount) var missingItemCount
  
  @Default(.photoGridItemLimit) var photoGridItemLimit
  @Default(.sidebarPosition) var sidebarPosition
  
  
  @State var presentation: BrowsePresentation = .grid
  @State var showStatusBar: Bool = true // Effectively a constant, but could be toggleable in the future
  @State var sidebarContentHeight: CGFloat = 0
  @State var showItemCountDetailsPopover: Bool = false
  

  var showBrowseRefinements: Binding<Bool> {
    .readOnly(panels.contains(.browseRefinements) || query.filterCount > 0)
  }
  
  var body: some View {
    @Bindable var appVM = appVM
    
    MainContent
      .sidebar(
        isPresented: appVM.bindToPanel(.sidebar),
        position: $sidebarPosition
      ) {
        SideBarContent
      }
      .withToolbarBackground(
        useTransparent: .constant(false)
      )
      .toolbar {
        if appVM.currentRoute.page == .folder {
          ToolbarItemGroup(placement: .navigation) {
            NavigationToolbarView(with: .browseItems)
          }
          
          ToolbarItemGroup(placement: .status) {
            BrowseScreenToolbar()
          }
          
          ToolbarItemGroup(placement: .primaryAction) {
            PresentationToggle(presentation: .grid, selection: $presentation)
            PresentationToggle(presentation: .table, selection: $presentation)
          }
        }
      }
      .statusBar(isPresented: .constant(true)) {
        StatusBarContent
      }
      .onPreferenceChange(StatusBarHeightKey.self) {
        sidebarContentHeight = $0
      }
      .buttonShortcut(binding: .editTags, action: exec.edit_EditTagsButton)
      .buttonShortcut(binding: .relocateSelection, action: exec.edit_MoveItemButton)
      .buttonShortcut(binding: .renameItem, action: exec.edit_RenameItemButton)
      .buttonShortcut(binding: .selectAll, action: exec.edit_SelectAllItemsButton)
  }
  
  var MainContent: some View {
    VStack(spacing: 8) {
      Ribbons
      
      Group {
        switch presentation {
        case .grid:
          PhotoGridView()
            .frame(minHeight: 0, maxHeight: .infinity)
        case .table:
          PhotoTableView()
        }
      }
      .padding(.bottom, sidebarContentHeight * 1.0) // Adjust for status bar height and sidebar
    }
  }

  var Ribbons: some View {
    FoldedPanel(isPresented: showBrowseRefinements) {
      BrowseRefinements()
        .padding(.horizontal, 8)
    }
    .panelStyle(.plain)
  }

  var SideBarContent: some View {
    ScrollView {
      VStack(spacing: 8) {
        BookmarksList(isPresented: appVM.bindToPanel(.bookmarks))
        Divider()
        WorkQueueSidebarMenu()
        Divider()
        ManageTagsView(isPresented: appVM.bindToPanel(.tagmanager))
      }
      .scenePadding()
    }
    .scrollIndicators(.never)
  }

  var StatusBarContent: some View {
    FullWidthSplit(spacing: 16) {
      QueryInfoIndicator
        .accessibilityLabel("Query Info")
      BrowsePath()
        .accessibilityLabel("Current folder: \(location.filepath.baseName)")
    } trailing: {
      ProfileInfoButton()
        .styleClass(.statusbar)
        .accessibilityLabel("Switch profiles")
        .accessibilityValue(profileName, isEnabled: true)
      #if DEBUG
      VolumeInfoButton(url: location)
        .styleClass(.statusbar)
      #endif
    }
    .overlay(GeometryReader { geo in
      Color.clear
        .preference(key: StatusBarHeightKey.self, value: geo.size.height)
    })
  }
  
  var QueryInfoIndicator: some View {
    Label(appVM.isLoadingContentItems ? .search.variant(.circle) : .info.variant(.circle))
      .popover(isPresented: $showItemCountDetailsPopover, arrowEdge: .top) {
        QueryInfoPopoverContent
      }
      .onTapGesture {
        showItemCountDetailsPopover.toggle()
      }
      .labelStyle(.iconOnly)
  }
  
  var QueryInfoPopoverContent: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Query Details")
        .font(.caption)
      
      Text("Total files: \(dbIndexCount)")
        .help("Total number of files that match the current parameters (tags, list mode, etc)")
        
      Text("\(hiddenItemCount) hidden")
        .help("Number of matching files in excess of the number that can be displayed at one time")
        .visible(hiddenItemCount > 0)
      
      Text("\(missingItemCount) missing")
        .help("Number of matching files that \(Constants.appname) has a record of, but are no longer accessible at the last known location")
        .visible(missingItemCount > 0)
    }
    .fillFrame(.horizontal)
    .padding()
    .frame(maxWidth: 200)
  }
}



#Preview("Browse Screen", traits: .defaultViewModel, .previewSize(.sq340.scaled(by: 2.0))) {
  VStack {
    BrowseScreen()
  }
  .windowTitlebarAppearsTransparent()
}
