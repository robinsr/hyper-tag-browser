// created on 5/11/25 by robinsr

extension KeyBinding {
  struct Group: Hashable, Identifiable, CaseIterable {
    var id: String = .randomIdentifier(10)
    var name: String
    var members: [KeyBinding]  = []
    
    static let generalGroup = Group(
      name: "Quick Actions",
      members: [
        .showPreferences, .help, .dismiss,
      ])
    
    static let navigationGroup = Group(
      name: "Navigating Folders",
      members: [
        .openDir,
        .forward,
        .goBack,
        .goForward,
        .back,
        .navDirUp,
        .reload
      ])
    
    static let editingGroup = Group(
      name: "Basic Editing",
      members: [
        .copy,
        .paste,
        .info,
        .editTags,
        .renameItem,
        .relocateSelection,
        .selectAll,
      ])
    
    static let queryGroup = Group(
      name: "Modify Query",
      members: [
        .toggleListMode,
        .toggleMatchOperator,
        .cycleSortMode,
        .toggleVisibility,
        .clearFilters
      ])
    
    static let displayGroup = Group(
      name: "Showing Stuff",
      members: [
        .showQuickActions,
        .showSearch,
        .toggleSidebar,
        .toggleSidebarPosition,
        .toggleManageTags,
        .toggleFilters,
        .toggleBookmarks,
        .toggleQueueList
      ])
    
    static let viewingGroup = Group(
      name: "Adjusting the View",
      members: [
        .browseGridMode,
        .browseTableMode,
        .decreaseTileSize,
        .increaseTileSize,
        .zoomActual,
        .zoomFitted,
        .toggleFillMode
      ])
    
    static let creationGroup = Group(
      name: "Creating Things",
      members: [
        .newQueue,
        .startIndexer,
      ])
    
    static let allCases: [Group] = [
      .generalGroup,
      .navigationGroup,
      .editingGroup,
      .queryGroup,
      .displayGroup,
      .viewingGroup,
      .creationGroup
    ]
  }

}
