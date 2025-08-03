// created on 4/26/25 by robinsr

import GRDB


struct DatabaseMaintainence {
  
  
  static let infillMissingContentTimestampsSQL = """
    UPDATE
      \(IndexRecord.databaseTableName)
    SET
      timestamp = CURRENT_TIMESTAMP
    WHERE
      timestamp IS NULL
  """
  
  
  
}
