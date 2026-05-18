// created on 1/12/26 by robinsr

import SwiftUI


@MainActor
@Observable
final class TagStashViewModel {
  
  init() {}
  
  var stashedTags: Set<FilteringTag> = []
  
  /// Tags as an Array (RandomAccessCollection for view iteration)
  var items: [FilteringTag] {
    stashedTags.asArray
  }
  
  var isEmpty: Bool {
    stashedTags.isEmpty
  }
  
  func unstash(tag: FilteringTag, from stashId: TagStash.StashId) {
    stashedTags.remove(tag)
  }
  
  func stash(tag: FilteringTag, in stashId: TagStash.StashId) {
    stashedTags.insert(tag)
  }
  
  func clearTagStash(id: TagStash.StashId) {
    stashedTags.removeAll()
  }
}
