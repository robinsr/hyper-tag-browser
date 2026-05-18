  // created on 11/16/24 by robinsr

import GRDB


/**
 Used for understanding how a tag is applied to content. Each `AppliedTagRecord` has
 one `TagRecord` and a row that joins all the contentId values that have that tag applied.
 */
@available(*, deprecated, message: "Unused as of 2025-05-14")
struct AppliedTagRecord: Codable, Identifiable, Filterable {
  var id: String
  var tagId: TagRecord.ID
  var tagValue: FilteringTag
  var appliedTo: String
  var appliedCount: Int
  var jsonIds: [ContentId]

  var asFilter: FilteringTag {
    tagValue
  }
  
  var contentIds: [ContentId] {
    appliedTo
      .split(on: ",")
      .compactMap {
        ContentId(existing: $0)
      }
  }
}
