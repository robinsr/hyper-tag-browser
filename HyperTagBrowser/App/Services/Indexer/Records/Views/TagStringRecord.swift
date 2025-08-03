// created on 11/7/24 by robinsr

import GRDB
import GRDBQuery

struct TagstringRecord: FetchableRecord, Codable {
  var contentId: ContentId
  var tagString: String
  var tagCount: Int
  
  enum CodingKeys: String, CodingKey {
    case contentId, tagString, tagCount
  }
  
  enum Columns: String, ColumnExpression {
    case contentId, tagString, tagCount
  }
}

extension TagstringRecord: DatabaseView {
  static let cteExpression = """
    SELECT 
      tagitem.contentId AS contentId,
      concatGroup(':' || tag.filterValue || ':') AS tagString,
      count(*) AS tagCount
    FROM 
      \(TagRecord.databaseTableName) tag
    JOIN
      \(IndexTagRecord.databaseTableName) tagitem
    ON
      tagitem.tagId = tag.id
    GROUP BY 
      contentId
  """
}

extension TagstringRecord: TableRecord {
  static let databaseTableName = "app_content_tag_items_joined"
}

// concatGroup(textConcat(':', tag.filterValue, ':')) AS tagString,
