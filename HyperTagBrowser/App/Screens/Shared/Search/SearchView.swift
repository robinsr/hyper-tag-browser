// created on 9/21/24 by robinsr

import CoreSpotlight
import CustomDump
import Defaults
import Factory
import Flow
import Observation
import SwiftUI
import OrderedCollections


struct SearchView: View, SheetPresentable {
  static let presentation: SheetPresentation = .full(controls: .all)
  
  @Environment(AppViewModel.self) var appVM

  @Environment(\.dispatcher) var dispatch
  @Environment(\.sheetControls) var sheetControls
  @Environment(\.sheetPadding) var sheetPadding
  
  @Environment(\.location) var location
  @Environment(\.dbBookmarks) var bookmarks
  
  @Default(.searchPerPageLimit) var itemLimit
  @Default(.searchMethod) var searchMethod
  
  @State var showDirPicker = false
  @State var locationOptions: [LocationGroup] = []
  
  @State var queryString: String = ""
  @State var queryLocation: URL = Container.shared.appViewModel().location
  @State var querySort: SortType = .createdAtDesc
  @State var queryMatch: FilterOperator = .and
  @State var queryPage: Int = 0
  
  @FocusState var fState: SearchViewFocus?
  
  
  // SearchMethod-agnostic container for search results
  // @State var searchState: SearchState = .ready
  
  init(withQuery query: String? = nil) {
    self._queryString = State(initialValue: query ?? "")
  }
  
  var searchState: SearchState { appVM.searchState }
  var searchResults: [ContentItem] { appVM.searchResults }
  var queryTerms: [SearchTerm] { appVM.searchQuery.searchTerms }
  
  var searchError: String? {
    switch searchState {
    case .errorMessage(let message):
      "Search error occured: \(message)"
    case .errorCode(let code):
      "Search error code: \(code)"
    default:
      nil
    }
  }
  
  var isLoading: Bool {
    switch searchState {
    case .searching: return true
    default: return false
    }
  }
  
  
  func startSearch(
    query: String? = nil,
    location: URL? = nil,
    sortBy: SortType? = nil,
    method: SearchMethod? = nil,
    matching: FilterOperator? = nil
  ) {
    
    // Update state values with new values
    queryString = query ?? queryString
    queryLocation = location ?? queryLocation
    querySort = sortBy ?? querySort
    searchMethod = method ?? searchMethod
    queryMatch = matching ?? queryMatch
    
    // Invoke relevant search method
    
    let query = SearchQuery(
      queryString: queryString,
      options: [],
      location: queryLocation.filepath,
      sorting: querySort,
      joining: queryMatch,
      paging: .default
    )
    
    dispatch(.startSearch(query))
  }
  
  
  func onSubmitSearch() {
    Task { startSearch() }
  }
  
  func onFormAppear() {
    Task {
      /// If search sheet is opened with pre-existing search string, update querystring state
      if queryString.notEmpty {
        startSearch()
      }
    }
    
    /// Automatically focus the text field when the search sheet appears
    fState = .query
  }
  
  func showPicker() {
    showDirPicker = true
  }
  
  
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      QueryTextField
        .padding(.bottom, 8)
      
      QueryRefinementOptions
        .padding(.bottom, 12)
      
      FullSheetDivider
      
      Group {
        TagSuggestionResults
        FullSheetDivider
      }
      .hidden(tags.count == 0)
      
      DebugInfoSection
        .debugVisible(flag: .views_debugSearch)
      
      ZStack(alignment: .center) {
        ScrollableFileResults
          .hidden(searchState.isLoading)
          .animation(.easeInOut(duration: 0.700), value: searchState.isLoading)
        
        ProgressView()
          .visible(searchState.isLoading)
          .animation(.easeInOut(duration: 0.700), value: searchState.isLoading)
      }
      .fillFrame([.horizontal, .vertical], alignment: .center)
      .withTestBorder(.pink)
    }
    .presentationBackgroundInteraction(.enabled)
    // TODO: the cache should be yanked higher
    .environment(\.dbContentItemsVisible, searchResults)
    .padding(.leading, -sheetPadding.leading)
    .padding(.trailing, -sheetPadding.trailing)
    .sheetView(isPresented: $showDirPicker, style: ChooseDirectoryForm.presentation) {
      ChooseFolderSheet
    }
  }
  
  var DebugInfoSection: some View {
    ContentRow {
      VStack {
        DebugSearchQueryTerms
        Defaults.SelectInput(.searchMethod)
          .frame(maxWidth: 280)
        Group {
          Text(appVM.searchQuery.description)
          Text(appVM.searchState.description)
        }
        .lineLimit(10)
        .monospacedDigit()
      }
    }
  }

  
    // MARK: - Form Input Views
  
  var QueryTextField: some View {
    ContentRow {
      TextField("", text: $queryString, prompt: Text("Search Files and Tags"))
        .textFieldStyle(.prominent(icon: .search))
        .onSubmit(self.onSubmitSearch)
        .onAppear(perform: self.onFormAppear)
    }
    .onChange(of: queryString, debounceTime: .milliseconds(800)) {
      tagSearchText = queryString.lastWord
    }
  }
  
  var QueryRefinementOptions: some View {
    ContentRow {
      ViewThatFits {
        HStack {
          QueryFolderMenu
          QuerySortMenu
          QueryMatchMenu
        }
        VStack(alignment: .leading, spacing: 12) {
          QueryFolderMenu
          QuerySortMenu
          QueryMatchMenu
        }
      }
    }
    .menuStyle(.inlineDropdown)
  }
  
  var QueryFolderMenu: some View {
    Group {
      FolderSelectMenu(data: locationOptions, onOther: showPicker) { url in
        startSearch(location: url)
      } label: {
        SelectInputLabel("Searching in:", "\(homeURL: queryLocation)")
      }
    }
    .onChange(of: queryLocation, initial: true) {
      locationOptions = [
        .named("Default Folder", Defaults[.profileOpenTo]),
        .parent(of: queryLocation),
        .contents(of: queryLocation),
        .adjacent(to: queryLocation),
        .named("Bookmarked Folders", bookmarks.map(\.content.url))
      ]
    }
  }
  
  var QuerySortMenu: some View {
    Menu {
      ForEach(SortType.allCases, id: \.self) { option in
        Button(option.description) {
          startSearch(sortBy: option)
        }
      }
    } label: {
      SelectInputLabel("Sorted by:", "\(querySort.description)")
    }
  }
  
  var QueryMatchMenu: some View {
    Menu {
      ForEach(FilterOperator.asSelectables, id: \.id) { option in
        Button(option.label) {
          startSearch(matching: option.value)
        }
      }
    } label: {
      if queryMatch == .and {
        SelectInputLabel("Matching:", "All terms")
      } else {
        SelectInputLabel("Matching:", "Any term")
      }
    }
  }
  
    // MARK: - Search Result Views
  
  @State var tags: [(Int, TagSuggestions.Suggestion)] = []
  
  @State var tagSearchText = ""
  
  let nonAlphaCharacters = CharacterSet.alphanumerics.inverted

  var TagSuggestionResults: some View {
    ContentRow {
      HStack {
        Text("Matching tags:")
          .styleClass(.controlLabel)
  
        ScrollView(.horizontal) {
          HStack(spacing: 8) {
            TagSuggestions(
              searchText: $tagSearchText,
              bindTo: $tags,
              numSuggestions: .constant(20),
              minTextNeeded: 2,
              searchDomains: [.attribution, .descriptive, .queue]
            ) { _, item in
              SuggestedTagButton(item)
            }
          }
        }
        .scrollIndicators(.never)
      }
    }
  }
  //HorizontalFlowView(spacing: 12) {
  
  func SuggestedTagButton(_ item: CountedTagRecord) -> some View {
    TagButton(
      for: item.asFilter,
      config: .init(
        variant: .secondary,
        contextMenuConfig: .sections([.refining, .searchable]),
        contextMenuDispatch: dispatch,
        onTap: { tag in
          if queryTerms.contains(tag.asSearchTerm) { return }
          
          if tag.value.contains(tagSearchText, caseSensitive: false) {
            startSearch(query: queryString.replacingLastWord(with: tag.asSearchString))
          } else {
            startSearch(query: queryString.appendingWord(tag.asSearchString))
          }
        }
      )
    )
  }
  
  var ScrollableFileResults: some View {
    ScrollView {
      ContentRow {
        LazyVStack(alignment: .leading, spacing: 20) {
          DividedForEach(searchResults, id: \.id) { result in
            SearchResultItem(
              content: result,
              searched: queryString.split(),
              queryLocation: queryLocation,
              updateQuery: { term in
                if queryTerms.contains(term) { return }
                
                startSearch(query: queryString.appendingWord(term.rawValue))
              }
            )
            .padding(.horizontal, 12)
          }
        }
      }
    }
  }
  
    // MARK: - Supporting Views
  
  func SelectInputLabel(_ title: String, _ value: String) -> some View {
    HStack {
      Text(verbatim: title).styleClass(.controlLabel)
      Text(verbatim: value)
    }
  }
  
  var ChooseFolderSheet: some View {
    ChooseDirectoryForm(
      onSelection: { path in
        showDirPicker = false
        startSearch(location: path.fileURL)
      },
      onCancel: {
        showDirPicker = false
      })
  }
  
  var LoadingIndicator: some View {
    ProgressView()
      .scaledToFill()
  }
  
  var FullSheetDivider: some View {
    Divider()
      .padding(.leading, -sheetPadding.leading)
      .padding(.trailing, -sheetPadding.trailing)
  }
  
  var DebugSearchQueryTerms: some View {
    HFlow {
      ForEach(queryTerms, id: \.id) { term in
        SearchTermToken(term: term)
      }
    }
  }
  
  func ContentRow<Content: View>(
    alignment: VerticalAlignment = .center,
    @ViewBuilder content: @escaping () -> (Content)
  ) -> some View {
    HStack(alignment: alignment, spacing: 12) {
      content()
    }
    .padding(.horizontal, 12)
    .fillFrame(.horizontal, alignment: .leading)
  }
  
  enum SearchViewFocus: Hashable {
    case query
  }
}



#Preview("Browse Screen", traits: .defaultViewModel, .fixedLayout(width: 600, height: 800)) {
  SearchView(withQuery: "#doggo")
    .scenePadding()
    .windowTitlebarAppearsTransparent()
}
