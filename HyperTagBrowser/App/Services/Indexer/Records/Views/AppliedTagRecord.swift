  // created on 11/16/24 by robinsr

import GRDB


/**
 Used for understanding how a tag is applied to content. Each `AppliedTagRecord` has
 one `TagRecord` and a row that joins all the contentId values that have that tag applied.
 */
@available(*, deprecated, message: "Unused as of 2025-05-14")
struct AppliedTagRecord: Codable, Identifiable, Filterable {
  var id: String
  var tagId: TagRecord.ID
  var tagValue: FilteringTag
  var appliedTo: String
  var appliedCount: Int
  var jsonIds: [ContentId]

  var asFilter: FilteringTag {
    tagValue
  }
  
  var contentIds: [ContentId] {
    appliedTo
      .split(on: ",")
      .compactMap {
        ContentId(existing: $0)
      }
  }
}

//extension AppliedTagRecord: TableRecord {
//  static let databaseTableName = "app_content_tag_content_ids"
//  
//  static let tag = belongsTo(
//    TagRecord.self,
//    using: .toThis(from: TagRecord.Columns.id, to: Columns.tagId))
//  
//  static let tagitems = hasMany(
//    IndexTagRecord.self,
//    using: .toThis(from: IndexTagRecord.Columns.tagId, to: Columns.tagId))
//}

//extension AppliedTagRecord: FetchableRecord {
//  enum CodingKeys: String, CodingKey {
//    case id, tagId, tagValue, appliedTo, appliedCount, jsonIds
//  }
//
//  enum Columns: String, ColumnExpression, CaseIterable {
//    case id, tagId, tagValue, appliedTo, appliedCount, jsonIds
//
//    var sqlExpression: SQLExpression {
//      switch self {
//      case .id:
//        Column("id").sqlExpression
//      case .tagId:
//        TagCols.id.sqlExpression
//      case .tagValue:
//        TagCols.filterValue.sqlExpression
//      case .appliedTo:
//        DatabaseFunctions.concatGroup.call(TagItemCols.contentId)
//      case .appliedCount:
//        count(Column("count"))
//      case .jsonIds:
//        Database.jsonGroupArray(TagItemCols.contentId)
//      }
//    }
//
//    var sqlSelection: SQLSelection {
//      sqlExpression.forKey(self)
//    }
//  }
//}

//extension AppliedTagRecord: DatabaseView {
//  
//  typealias TagCols = TagRecord.Columns
//  typealias TagItemCols = IndexTagRecord.Columns
//  
//  static var cteRequest: QueryInterfaceRequest<AppliedTagRecord> {
//    IndexTagRecord
//      .all()
//      .select(Columns.allCases.map(\.sqlSelection))
//      .joining(required: tagitems)
//      .asRequest(of: AppliedTagRecord.self)
//  }
//  
//  
//  static let cteExpression = """
//    SELECT
//      tag.id as tagId,
//      tag.filterValue AS value,
//      concatGroup(tagitem.contentId) AS contentIds,
//      count(*) AS count
//    FROM 
//      \(IndexTagRecord.databaseTableName) tagitem
//    JOIN 
//      \(TagRecord.databaseTableName) tag
//    ON 
//      tagitem.tagId = tag.id
//    GROUP BY
//      tag.id
//  """
//}


//extension DerivableRequest<AppliedTagRecord> {
//  private typealias Cols = AppliedTagRecord.Columns
//  
//  func withContentIds(_ ids: [ContentId]) -> Self {
//    let likeStmts = ids
//      .map { Cols.appliedTo.like("%\($0)%") }
//      .joined(operator: .and)
//    
//    return self.filter(likeStmts)
//  }
//}
//
//extension AppliedTagRecord {
//  static func withContentIds(_ ids: [ContentId]) -> QueryInterfaceRequest<Self> {
//    return Self.all()
//      .select(Columns.tagId)
//      .withContentIds(ids)
//  }
//}

