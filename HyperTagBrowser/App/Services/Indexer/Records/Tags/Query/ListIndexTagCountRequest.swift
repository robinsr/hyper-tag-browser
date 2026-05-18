// created on 11/25/25 by robinsr

import GRDB
import GRDBQuery

struct ListIndexTagCountRequest: ValueObservationQueryable {
  typealias IndexTagCountMap = [ContentId:Int]

  static let queryableOptions = QueryableOptions.async
  static var defaultValue: IndexTagCountMap = [:]

  var contentIds: [ContentId] = []

  func fetch(_ db: Database) throws -> IndexTagCountMap {
    let request = IndexTagCountRecord.all().forContent(contentIds)

    return try timeRequest {
      try prepare(db, request) { req in
        let result = try req.fetchAll(db)
        
        return result.reduce(into: [:]) { counts, record in
          counts[record.contentId] = record.tagCount
        }
      }
    }
  }
}
