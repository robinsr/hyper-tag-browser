// created on 5/24/25 by robinsr

import Foundation
import GRDB


struct SavedQueryRecord: Codable, Identifiable, Equatable, Hashable {
  var id: BrowseFilters.ID
  var name: String
  var query: BrowseFilters
  var createdAt: Date
  var updatedAt: Date
  
  init(id: BrowseFilters.ID, name: String, query: BrowseFilters, createdAt: Date? = nil, updatedAt: Date? = nil) {
    //self.id = id.withPrefix("query:")
    self.id = id
    self.name = name
    self.query = query
    self.createdAt = createdAt ?? .now
    self.updatedAt = updatedAt ?? .now
  }
  
  init(name: String, query: BrowseFilters) {
    //self.id = query.id.withPrefix("query:")
    self.id = query.id
    self.name = name
    self.query = query
    self.createdAt = Date.now
    self.updatedAt = Date.now
  }
}


extension SavedQueryRecord: TableRecord {
  static let databaseTableName = "app_saved_content_queries"
}


extension SavedQueryRecord: PersistableRecord, FetchableRecord {
  
  enum CodingKeys: String, CodingKey, CaseIterable {
    case id, name, query, createdAt, updatedAt
  }
  
  enum Columns {
    static let id = Column(CodingKeys.id)
    static let name = Column(CodingKeys.name)
    static let query = JSONColumn(CodingKeys.query)
    static let createdAt = Column(CodingKeys.createdAt)
    static let updatedAt = Column(CodingKeys.updatedAt)
  }
}

extension DerivableRequest<SavedQueryRecord> {
  func withId(_ id: SavedQueryRecord.ID) -> Self {
    filter(SavedQueryRecord.Columns.id.equals(id))
  }
}


extension SavedQueryRecord {
  static func createTable(_ db: Database) throws {
    try db.create(table: SavedQueryRecord.databaseTableName) { table in
      table.id("id")
      table.column("name",      .text).notNull()
      table.column("query",     .jsonText).notNull()
      table.column("createdAt", .datetime).notNull().timestamp()
      table.column("updatedAt", .datetime).notNull().timestamp()
    }
  }
}
