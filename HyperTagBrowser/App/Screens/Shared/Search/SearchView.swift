// created on 9/21/24 by robinsr

import CustomDump
import Defaults
import Factory
import Flow
import Observation
import SwiftUI


struct SearchView: View, SheetPresentable {
  static let presentation: SheetPresentation = .full(controls: .all)
  
  @State private var model = SearchModel()
  @State private var name = ""
  
  @Environment(\.dispatcher) var dispatch
  @Environment(\.sheetControls) var sheetControls
  @Environment(\.sheetPadding) var sheetPadding
  @Environment(\.location) var location
  
  @State var showDirPicker = false
  @FocusState var fState: SearchViewFocus?
  
  
  // SearchMethod-agnostic container for search results
  // @State var searchState: SearchState = .ready
  
  init(withQuery initial: String? = nil) {
    if let queryString = initial {
      model.queryString = queryString
    }
  }
  
  var searchState: SearchState { model.searchState }
  var queryTerms: [SearchTerm] { model.query.searchTerms }
  var queryString: String { model.queryString }
  var queryLocation: URL { model.queryLocation }
  var locationOptions: [LocationGroup] { model.locationOptions }
  
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
    searchState == .searching
  }
  
  func submitSearch() {
    Task { await model.startSearch() }
  }
  
  func onFormAppear() {
    // Sync SearchModel's location value with AppViewModel
    model.queryLocation = location
    
    // If search sheet is opened with pre-existing search string, update querystring state
    if model.queryString.notEmpty {
      submitSearch()
    }
    
    // Automatically focus the text field when the search sheet appears
    fState = .query
  }
  
  var body: some View {
    SearchSheetContent
      .presentationBackgroundInteraction(.enabled)
      .environment(model)
      .environment(\.dbContentItemsVisible, model.searchResults)
      .sheetView(isPresented: $showDirPicker, style: ChooseDirectoryForm.presentation) {
        ChooseFolderSheet
      }
      .task(id: model.tagQueryString) {
        model.startTagObservation(model.tagQueryString)
        model.startBookmarkObservation("SearchView")
      }
      .onAppear(perform: self.onFormAppear)
  }
  
  var SearchSheetContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      QueryTextField
        .padding(.bottom, 8)
        .withTestBorder(.pink)
      
      QueryRefinementOptions
        .padding(.bottom, 12)
        .withTestBorder(.cyan)
      
      SheetDivider
      
      Group {
        TagSuggestionResults
        SheetDivider
      }
      .hidden(model.suggestedTags.count == 0)
      .withTestBorder(.orange)
      
      DebugInfoSection
        .debugVisible(flag: .views_debugSearch)
      
      ZStack(alignment: .center) {
        ScrollableFileResults
          .opacity(searchState.isLoading ? 0 : 1.0)
          .animation(.easeInOut(duration: 0.7), value: searchState.isLoading)
        
        LoadingIndicator
          .opacity(searchState.isLoading ? 1.0 : 0)
          .animation(.easeInOut(duration: 0.7), value: searchState.isLoading)
      }
      .fillFrame([.horizontal, .vertical], alignment: .center)
      .withTestBorder(.pink)
    }
    .padding(.leading, -sheetPadding.leading)
    .padding(.trailing, -sheetPadding.trailing)
  }
  
    // MARK: - Form Input Views
  
  var QueryTextField: some View {
    @Bindable var model = model
    
    return ContentRow {
      TextField("", text: $model.queryString, prompt: Text("Search Files and Tags"))
        .textFieldStyle(.prominent(icon: .search))
        .onSubmit(self.submitSearch)
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
      FolderSelectMenu(
        data: locationOptions,
        onOther: { showDirPicker = true }
      ) { url in
        model.queryLocation = url
        submitSearch()
      } label: {
        SelectInputLabel("Searching in:", "\(homeURL: model.queryLocation)")
      }
    }
  }
  
  var QuerySortMenu: some View {
    Menu {
      ForEach(SortType.allCases, id: \.self) { option in
        Button(option.description) {
          model.querySort = option
          submitSearch()
        }
      }
    } label: {
      SelectInputLabel("Sorted by:", "\(model.querySort.description)")
    }
  }
  
  var QueryMatchMenu: some View {
    Menu {
      ForEach(FilterOperator.asSelectables, id: \.id) { option in
        Button(option.label) {
          model.queryMatch = option.value
          submitSearch()
        }
      }
    } label: {
      if model.queryMatch == .and {
        SelectInputLabel("Matching:", "All terms")
      } else {
        SelectInputLabel("Matching:", "Any term")
      }
    }
  }
  
    // MARK: - Search Result Views
  
  let nonAlphaCharacters = CharacterSet.alphanumerics.inverted

  var TagSuggestionResults: some View {
    ContentRow {
      HStack {
        Text("Matching tags:")
          .styleClass(.controlLabel)
  
        ScrollView(.horizontal) {
          HStack(spacing: 8) {
            ForEach(model.suggestedTags) { item in
              SuggestedTagButton(item)
            }
          }
        }
        .scrollIndicators(.never)
      }
    }
  }
  
  func SuggestedTagButton(_ item: CountedTagRecord) -> some View {
    TagButton(
      for: item.asFilter,
      config: .init(
        variant: .primary,
        menu: .tagMenu(when: .refiningSearchQuery),
        onMenuItem: dispatch,
        onTap: { tag in
          model.takeTagSuggestion(tag)
        }
      )
    )
  }
  
  var ScrollableFileResults: some View {
    ScrollView {
      ContentRow {
        LazyVStack(alignment: .leading, spacing: 20) {
          DividedForEach(model.searchResults, id: \.id) { result in
            SearchResultItem(content: result)
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
        model.queryLocation = path.fileURL
        submitSearch()
      },
      onCancel: {
        showDirPicker = false
      })
  }
  
  var LoadingIndicator: some View {
    ProgressView()
      .scaledToFill()
  }
  
  var SheetDivider: some View {
    Divider()
      .padding(.leading, -sheetPadding.leading)
      .padding(.trailing, -sheetPadding.trailing)
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
  
  //
  // MARK: - Debug Views
  //
  
  var DebugInfoSection: some View {
    ContentRow {
      VStack {
        DebugSearchQueryTerms
        Defaults.SelectInput(.searchMethod)
          .frame(maxWidth: 280)
        Group {
          Text(model.query.description)
          Text(model.tagQueryString)
          Text(model.searchState.description)
        }
        .lineLimit(10)
        .monospacedDigit()
      }
    }
  }
  
  var DebugSearchQueryTerms: some View {
    HFlow {
      ForEach(queryTerms, id: \.id) { term in
        SearchTermToken(term: term)
      }
    }
  }
}



#Preview("Browse Screen", traits: .defaultViewModel, .fixedLayout(width: 600, height: 800)) {
  SearchView(withQuery: "#doggo")
    .scenePadding()
    .windowTitlebarAppearsTransparent()
}
