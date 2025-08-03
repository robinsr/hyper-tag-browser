// created on 12/7/24 by robinsr


/**
 * A type that represents the focus state of a content item, which can be
 * targeted for receiving either a tag or file
 */
enum ContentIdFocusable: Hashable {

  /// View is not receiving any type of focus
  case unset

  /// View is receiving focus when a tag (or tags) is selected
  case receivingTag(on: ContentPointer)

  /// View is receiving focus when a content item (or items) is selected
  case receivingFile(on: ContentPointer)

  /// View is disallowed from receiving focus for the given content pointer
  case disallowed(on: ContentPointer)

  
  var contentPointer: ContentPointer? {
    switch self {
      case .receivingTag(let pointer), .receivingFile(let pointer):
        return pointer
      default:
        return nil
    }
  }

  func isTargeted(_ contentId: ContentId) -> Bool {
    contentId == contentPointer?.contentId
  }

  var dropType: Any.Type {
    switch self {
      case .receivingTag: return FilteringTag.self
      case .receivingFile: return ContentItem.self
      default: return Void.self
    }
  }
}


extension Sequence where Element == ContentIdFocusable {

  var ids: [ContentId] {
    compactMap(\.contentPointer?.contentId)
  }

  /**
   * Returns true if any of the elements in the sequence are receiving focus
   * for the given content item id
   */
  func isTargeted(_ id: ContentId) -> Bool {
    first(where: { $0.isTargeted(id) }) != nil
  }

  /**
   * Same as `isTargeted(id:)` but might be less efficient
   */
  func contains(id: ContentId) -> Bool {
    ids.contains(id)
  }

  /**
   * Returns true if all elements in the sequence are not receiving focus
   */
  var isUnset: Bool {
    allSatisfy { $0 == .unset }
  }

  /**
   * Returns the elements of the sequence that have a differing `dropType` than the given target type.
   */
  func dropingAll(for targetType: Any.Type) -> [Element] {
    filter { $0.dropType == targetType }.map { $0 }
  }
}
