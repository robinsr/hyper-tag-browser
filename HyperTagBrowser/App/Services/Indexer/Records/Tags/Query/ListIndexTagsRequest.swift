// created on 11/6/24 by robinsr

import GRDB
import GRDBQuery

struct ListIndexTagsRequest: ValueObservationQueryable {
  typealias Cols = IndexTagValueRecord.Columns

  static let queryableOptions = QueryableOptions.async
  static var defaultValue: [IndexTagValueRecord] { [] }

  var contentId: ContentId? = nil
  var tagDomains: [FilteringTag.TagDomain] = [.descriptive, .attribution]

  func fetch(_ db: Database) throws -> [IndexTagValueRecord] {
    guard contentId != nil else { return [] }

    let request = IndexTagValueRecord.all()
      .forContent(contentId!)
      .withTagDomain(tagDomains)
      .orderByTagValue(reversed: false)

    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
