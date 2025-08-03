// created on 10/28/24 by robinsr

import Defaults
import Foundation
import GRDB
import GRDBQuery
import CustomDump
import UniformTypeIdentifiers


/**
 A basic observable query on ``IndexRecord`` table, returning a list of ``IndexRecord``s
 matching the supplied parameters (essentially just table rows, no JOINs)
 */
struct ListIndexesRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: [IndexInfoRecord] { [] }
  
  var contentIds: [ContentId] = []
  
  func fetch(_ db: Database) throws -> [IndexInfoRecord] {
    if contentIds.isEmpty {
      return []
    }
    
    let request = IndexInfoRecord.info(ids: contentIds)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
