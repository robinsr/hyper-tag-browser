// created on 3/18/25 by robinsr

import Foundation
import GRDB


struct LocationRecord: Codable, Identifiable {
  var id: ContentId
  var filepath: URL
  
  enum CodingKeys: String, CodingKey {
    case id
    case filepath
  }
}

extension LocationRecord: TableRecord, PersistableRecord {
  static let databaseTableName = "app_locations"
  
  enum Columns {
    static let id = Column(CodingKeys.id)
    static let filepath = Column(CodingKeys.filepath)
  }
}
