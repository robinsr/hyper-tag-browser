// created on 10/27/24 by robinsr


import DebouncedOnChange
import Factory
import SwiftUI


struct TagSuggestions<Content: View>: View {
  typealias Suggestion = CountedTagRecord
  
  private var logger = EnvContainer.shared.logger("TagSuggestions")
  
  @Binding var searchText: String
  @Binding var selectedItems: [ContentId]
  @Binding var excludedTags: [FilteringTag]
  @Binding var bindTo: [(Int, Suggestion)]
  @Binding var numSuggestions: Int
  var searchDomains: [FilteringTag.TagDomain]
  var minTextNeeded: Int
  @ViewBuilder var content: (Int, Suggestion) -> Content
  
  @State var model = SuggestionViewModel()
  
  /**
   * Initialize a TagSuggestions view
   *
   * - Parameters:
   *    - searchText: The text to search for
   *    - selectedItems: Limit to just those tags applied to the selected content items
   *    - excludedTags: Exclude these tags from the suggestions (e.g. those already applied)
   *    - bindTo: Optionally store suggestions for external use
   *    - numSuggestions: Number of suggestions to return
   *    - minTextNeeded: Minimum number of characters needed to trigger a data fetch
   *    - content: The content to display for each suggestion
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
    ForEach(model.indexed, id: \.1.id) { index, item in
      content(index, item)
        .id(item.id)
    }
    .onChange(of: searchText, initial: true, debounceTime: .milliseconds(300)) {
      let text = searchText.count >= minTextNeeded ? searchText : ""
      
      model.searchText = text
      model.userDidChangeQuery()
    }
    .onChange(of: numSuggestions) {
      model.itemLimit = numSuggestions + 3
      model.userDidChangeQuery()
    }
    .onChange(of: excludedTags) {
      model.excludedTags = excludedTags
      model.userDidChangeQuery()
    }
    .onChange(of: selectedItems) {
      model.excludedContentIds = selectedItems
      model.userDidChangeQuery()
    }
  }
}
