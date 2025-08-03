// created on 6/2/25 by robinsr

/**
 * Defines properties that are common to all tag associations types
 */
protocol TagAssociation {
  var tagId: String { get }
  var contentId: ContentId { get }
}

extension Sequence where Element: TagAssociation {
  
  /// Returns a set of all tag IDs in this sequence
  var tagIds: Set<String> {
    self.map(\.tagId).asSet
  }
  
  /// Returns a set of `TagAssociation` values from the sequence that match the given content ID.
  func forContent(_ contentId: ContentId) -> [Element] {
    filter { $0.contentId == contentId }
  }
  
  /// Returns the first `TagAssociation` that matches the given tag ID.
  func first(whereTagId tagId: String) -> Element? {
    first { $0.tagId == tagId }
  }
}
