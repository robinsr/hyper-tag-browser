// created on 10/14/24 by robinsr

import Foundation
import UniformTypeIdentifiers
import GRDB
import GRDBQuery


/**
 Associates a ``TagRecord`` with a ``IndexRecord`` via ``ContentId``
 */
struct IndexTagRecord: Identifiable, TableRecord, TagAssociation {
  static let databaseTableName = "app_content_tag_items"
  
  var id: String = .randomIdentifier(24, prefix: "tagitem:")
  var tagId: String
  var contentId: ContentId
  
  init(id: String = .randomIdentifier(24, prefix: "tagitem:"), tagId: String, contentId: ContentId) {
    self.id = id
    self.tagId = tagId
    self.contentId = contentId
  }
  
  init(tag: TagRecord, contentId: ContentId) {
    self.id = String.randomIdentifier(24)
    self.tagId = tag.id
    self.contentId = contentId
  }
}


extension IndexTagRecord: Codable, FetchableRecord, PersistableRecord  {
  enum CodingKeys: String, CodingKey {
    case id, tagId, contentId
  }
  
  enum Columns: String, ColumnExpression {
    case id, tagId, contentId
  }
  
  static let tag = hasOne(
    TagRecord.self,
    using: ForeignKey([TagRecord.Columns.id], to: [Columns.tagId])
  )
  
  static let content = hasOne(IndexRecord.self)
  
  static func forContent(_ contentId: ContentId) -> QueryInterfaceRequest<Self> {
    IndexTagRecord.filter(Columns.contentId.equals(contentId.value))
  }
  
  static func forContent(_ contentIds: [ContentId]) -> QueryInterfaceRequest<Self> {
    IndexTagRecord.filter(Columns.contentId.in(contentIds.values))
  }
}


extension DerivableRequest<IndexTagRecord> {
  private typealias Cols = IndexTagRecord.Columns
  private typealias TagCols = TagRecord.Columns
  
  func matching(filter tags: [FilteringTag]) -> Self {
    including(required: IndexTagRecord.tag.filter(
      tags.map(\.rawValue).contains(TagCols.filterValue)
    ))
  }
  
  func matching(filter: FilteringTag) -> Self {
    matching(filter: [filter])
  }
  
  func matching(contentId id: ContentId) -> Self {
    filter(Cols.contentId == id)
  }
  
  func matching(contentId ids: [ContentId]) -> Self {
    filter(ids.contains(Cols.contentId))
  }
  
  func matching(tagId id: TagRecord.ID) -> Self {
    filter(Cols.tagId == id)
  }
  
  func matching(tagId ids: [TagRecord.ID]) -> Self {
    filter(ids.contains(Cols.tagId))
  }

  func countAll() -> Self {
    let countCol = Column("*")
    
    return self
      .all()
      .select(Cols.tagId, count(countCol))
      .group(Cols.tagId)
  }
}
