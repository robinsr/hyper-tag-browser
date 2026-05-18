// created on 2/2/25 by robinsr


/**
 * Defines common scenarios where a `FilteringTag` is displayed in the app.
 * Used for creating standardized context menu options based on scenario/context.
 */
enum TagMenuContext: Sendable, Equatable, Hashable {
  
  /// The tag is currently associated with a content item.
  case taggedOn(ContentItem)
  
  /// The tag is suggested for association but not currently applied.
  case taggingContent
  
  /// The tag is suggested as a filter but not currently applied.
  case addingBrowseFilters
  
  /// The tag is currently applied as a filter.
  case editingBrowseFilters
  
  /// The tag is suggested when searching content
  case refiningSearchQuery
  
  /// Edge cases where context isn't available; results in minimum configuration
  case noContext
}
