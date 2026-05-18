// created on 11/25/25 by robinsr

import GRDB


struct IndexTagCountRecord: FetchableRecord, Codable, Hashable {
  var contentId: ContentId
  var tagCount: Int
  
  var id: String {
    contentId.value
  }
  
  enum CodingKeys: String, CodingKey {
    case contentId, tagCount
  }
  
  public enum Columns: String, ColumnExpression {
    case contentId, tagCount
  }
}

extension DerivableRequest<IndexTagCountRecord> {
  private typealias Cols = IndexTagCountRecord.Columns
  private typealias IndxTagCols = IndexTagRecord.Columns
  private typealias TagCols = TagRecord.Columns

  func forContent(_ contentIds: [ContentId]) -> Self {
    filter(Cols.contentId.in(contentIds))
  }
}

extension IndexTagCountRecord: DatabaseView {
  static let cteExpression = """
    SELECT
      tagitem.contentId AS contentId,
      COUNT(*) as tagCount
    FROM 
      \(IndexTagRecord.databaseTableName) tagitem
    GROUP BY
      tagitem.contentId
    """
}
