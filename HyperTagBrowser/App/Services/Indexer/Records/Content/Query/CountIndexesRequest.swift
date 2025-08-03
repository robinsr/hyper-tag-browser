// created on 10/28/24 by robinsr

import Foundation
import GRDB
import GRDBQuery
import CustomDump
import UniformTypeIdentifiers

/**
 A request to count the number of ``IndexRecord``s selected by
 parameters configured in a ``IndxRequestParams`` 
 */
struct CountIndexesRequest: ValueObservationQueryable {
  static let queryableOptions = QueryableOptions.async
  static var defaultValue: Int { 0 }
  
  var parameters: IndxRequestParams?

  func fetch(_ db: Database) throws -> Int {
    guard let params = parameters else {
      return 0
    }
    
    let request = IndexRecord
      .all()
      .applyingParams(params)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchCount(db)
      }
    }
  }
}
