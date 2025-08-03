// created on 10/27/24 by robinsr


import DebouncedOnChange
import Factory
import SwiftUI


struct TagSuggestions<Content: View>: View {
  typealias Suggestion = CountedTagRecord
  
  var logger = EnvContainer.shared.logger("TagSuggestions")
  
  @Injected(\IndexerContainer.indexService) private var indexService
  
  @Binding var searchText: String
  @Binding var selectedItems: [ContentId]
  @Binding var excludedTags: [FilteringTag]
  @Binding var bindTo: [(Int, Suggestion)]
  @Binding var numSuggestions: Int
  var searchDomains: [FilteringTag.TagDomain]
  var minTextNeeded: Int
  @ViewBuilder var content: (Int, Suggestion) -> Content
  
  @State var queryParams: TagQueryParameters = TagQueryParameters(queryText: "")
  @State var queryResults: [(Int, Suggestion)] = []
  
  
  /**
   Initialize a TagSuggestions view
   
   - Parameters:
      - searchText: The text to search for
      - selectedItems: Limit to just those tags applied to the selected content items
      - excludedTags: Exclude these tags from the suggestions (e.g. those already applied)
      - bindTo: Optionally store suggestions for external use
      - numSuggestions: Number of suggestions to return
      - minTextNeeded: Minimum number of characters needed to trigger a data fetch
      - content: The content to display for each suggestion
   */
  init(
    searchText: Binding<String>,
    selectedItems: Binding<[ContentId]> = .constant([]),
    excludedTags: Binding<[FilteringTag]> = .constant([]),
    bindTo: Binding<[(Int, Suggestion)]> = .constant([]),
    numSuggestions: Binding<Int> = .constant(5),
    minTextNeeded: Int = 2,
    searchDomains: [FilteringTag.TagDomain] = [.attribution, .descriptive],
    @ViewBuilder content: @escaping (Int, Suggestion) -> Content
  ) {
    self._searchText = searchText
    self._selectedItems = selectedItems
    self._excludedTags = excludedTags
    self._bindTo = bindTo
    self._numSuggestions = numSuggestions

    self.minTextNeeded = minTextNeeded
    self.searchDomains = searchDomains
    self.content = content
  }
  
  var body: some View {
    ForEach(queryResults, id: \.1.id) { index, item in
      content(index, item)
        .id(item.id)
    }
    .onAppear {
      queryParams = TagQueryParameters(
        queryText: $searchText.wrappedValue.trimmingCharacters(in: .whitespaces),
        tagDomains: searchDomains,
        excludingTags: $excludedTags.wrappedValue,
        excludingContent: $selectedItems.wrappedValue,
        itemLimit: $numSuggestions.wrappedValue + 3
      )
    }
    .onChange(of: queryParams, initial: true, debounceTime: .milliseconds(300)) {
      fetch()
    }
    .onChange(of: searchText) {
      queryParams.queryText = searchText.trimmingCharacters(in: .whitespaces)
    }
    .onChange(of: numSuggestions) {
      queryParams.itemLimit = numSuggestions + 3
    }
    .onChange(of: excludedTags) {
      queryParams.excludingTags = excludedTags
    }
    .onChange(of: selectedItems) {
      queryParams.excludingContent = selectedItems
    }
  }
  
  private func fetch() {
    Task.detached(priority: .userInitiated) {
      let suggestions = await requestSuggestions().enumerated().map { ($0, $1) }
      
      DispatchQueue.main.async {
        if suggestions.isEmpty {
          queryResults = []
          bindTo = []
        } else {
          queryResults = suggestions
          bindTo = suggestions  // .enumerated().map { ($0, $1) }
        }
      }
    }
  }
  
  private func requestSuggestions() async -> [Suggestion] {
    do {
      return try indexService.queryTags(matching: queryParams)
    } catch {
      logger.emit(.error, ErrorMsg("Failed to query for tag suggestions", error))
    }
    
    return queryResults.map { $1 }  // return what we have so far
  }
}






//    .overlay {
//      if let error = $searchResults.error {
//        Text("Error loading suggestions: \(String(describing: error))")
//          .styleClass(.errorDetails)
//          .background(.background)
//      }
//    }
//    .onChange(of: searchResults) {
//      bindTo = suggestions
//    }
//      $searchResults.queryText.wrappedValue = searchText
//      $searchResults.limit.wrappedValue = numSuggestions + 3
//      $searchResults.excludingTags.wrappedValue = excludedTags
//      $searchResults.excludingTagsOnContent.wrappedValue = selectedItems
