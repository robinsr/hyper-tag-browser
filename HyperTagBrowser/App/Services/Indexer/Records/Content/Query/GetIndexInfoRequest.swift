// created on 10/28/24 by robinsr

import Defaults
import Foundation
import GRDB
import GRDBQuery
import CustomDump
import Factory


/**
  Queryable for single `IndexInfoRecord` from the database
*/
struct GetIndexInfoRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: IndexInfoRecord? { nil }

  var contentId: ContentId?

  func fetch(_ db: Database) throws -> IndexInfoRecord? {
    
    guard let id = contentId else {
      return nil
    }
    
    let request = IndexInfoRecord.info(ids: [id])
    
    return try timeRequest {
      let result = try prepare(db, request) { req in
        try req.fetchAll(db)
      }
      
      return result.first
    }
  }
}
