// created on 2/21/25 by robinsr


/**
 * Conformance to `Filterable` indicates that the type can be represented as a filtering tag.
 *
 * With conformance, collections of `Filterable` types can be easily transformed into sets of filtering tags or IDs.
 */
protocol Filterable: Identifiable {
  var asFilter: FilteringTag { get }
}


extension Sequence where Element: Filterable {

  /// Returns the elements mapped to their filtering tag IDs
  var tagIds: Set<Element.ID> {
    self.map(\.id).asSet
  }

  /// Returns the elements mapped to their filtering tags
  var filteringTags: Set<FilteringTag> {
    self.map(\.asFilter).asSet
  }
  
  /// Returns the elements mapped to their filtering tag values
  var tagValues: Set<String> {
    self.map(\.asFilter.rawValue).asSet
  }
}
