// created on 10/14/24 by robinsr

import GRDB
import GRDBQuery


struct ListIndexInfoRequest: ValueObservationQueryable {
  static let queryableOptions = [QueryableOptions.async, .constantRegion]
  
  static var defaultValue: [IndexInfoRecord] { [] }
  
  var parameters: IndxRequestParams?
  
  var resultCache: Dictionary<String, [IndexInfoRecord]> = [:]
  

  func fetch(_ db: Database) throws -> [IndexInfoRecord] {
    guard let params = parameters else {
      return []
    }
    
    let parameterHash = params.hashValue
    
    // check if parameter hash is already cached
    
    if let cachedResult = resultCache[String(parameterHash)] {
      return cachedResult
    }
    
    if params.root == .null {
      return []
    }
    
    let request = IndexInfoRecord.info(matching: params)
    
    return try timeRequest {
      try prepare(db, request) { req in
        try req.fetchAll(db)
      }
    }
  }
}
