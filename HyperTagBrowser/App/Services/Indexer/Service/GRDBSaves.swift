// created on 5/25/25 by robinsr

import Foundation
import GRDB


extension GRDBIndexService: SavedQueryAccess {
  
  typealias Columns = SavedQueryRecord.Columns
  
  
  func savedQueryExists(withId id: SavedQueryRecord.ID) throws -> Bool {
    try dbReader.read { db in
      try SavedQueryRecord.filter(Columns.id.equals(id)).isEmpty(db) == false
    }
  }
  
  
  func getSavedQuery(withId id: SavedQueryRecord.ID) throws -> SavedQueryRecord? {
    try dbReader.read { db in
      try SavedQueryRecord.filter(Columns.id.equals(id)).fetchOne(db)
    }
  }
  
  
  func listSavedQueries() throws -> [SavedQueryRecord] {
    try dbReader.read { db in
      try SavedQueryRecord.all().order(Columns.createdAt.desc).fetchAll(db)
    }
  }
  
  
  func createSavedQuery(named queryName: String, using query: BrowseFilters) throws -> SavedQueryRecord {
    try dbWriter.write { db in
      let query = SavedQueryRecord(name: queryName, query: query)
      try query.insert(db)
      return query
    }
  }
  
  
  func updateSavedQuery(withId id: SavedQueryRecord.ID, using query: BrowseFilters) throws -> SavedQueryRecord {
    try dbWriter.write { db in
      guard var record = try getSavedQuery(withId: id) else {
        throw IndexerServiceError.DataIntegrityError("Expected to find SavedQuery with id \(id.quoted)", attributes: [:])
      }
      
      record.query = query
      record.updatedAt = Date.now
      
      try record.update(db)
      
      return record
    }
  }
  
  
  func renameSavedQuery(withId: SavedQueryRecord.ID, to: String) throws -> SavedQueryRecord {
    try dbWriter.write { db in
      guard var record = try getSavedQuery(withId: withId) else {
        throw IndexerServiceError.DataIntegrityError("Expected to find SavedQuery with id \(withId.quoted)", attributes: [:])
      }
      
      record.name = to
      record.updatedAt = Date.now
      
      try record.update(db)
      
      return record
    }
  }
  
  
  func deleteSavedQuery(withId: SavedQueryRecord.ID) throws -> Bool {
    try dbWriter.write { db in
      guard let record = try getSavedQuery(withId: withId) else {
        throw IndexerServiceError.DataIntegrityError("Expected to find SavedQuery with id \(withId.quoted)", attributes: [:])
      }
      
      try record.delete(db)
      return true
    }
  }
}
