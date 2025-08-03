// created on 10/28/24 by robinsr

import Foundation
import GRDB
import GRDBQuery
import System


struct ListIndexLocationsRequest: ValueObservationQueryable {
  static let queryableOptions = GRDBIndexService.queryableOptions
  
  static var defaultValue: [FilePath] { [] }

  func fetch(_ db: Database) throws -> [FilePath] {
    let request = IndexRecord.distinctLocations()
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
