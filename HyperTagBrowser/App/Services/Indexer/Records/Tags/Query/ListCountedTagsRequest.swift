// created on 11/6/24 by robinsr

import Defaults
import GRDB
import GRDBQuery
import SwiftUI


struct ListCountedTagsRequest: ValueObservationQueryable {
  static let queryableOptions = GRDBIndexService.queryableOptions
  static var defaultValue: [CountedTagRecord] { [] }

  var parameters: TagQueryParameters = .init(
    queryText: "",
    excludingTags: [],
    excludingContent: [],
    itemLimit: 25
  )
  
  func fetch(_ db: Database) throws -> [CountedTagRecord] {
    let request = CountedTagRecord.query(matching: parameters)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
