// created on 11/16/24 by robinsr

import GRDB


/**
 * Produces the same table as `IndexTagRecord`, but annotated with the tag's value.
 *
 * Joins `IndexTagRecord` andd `TagRecord` to provide a view of the actual tag
 * values associated with a content item (as opposed to just the tag IDs).
 *
 * A `IndexRecord` will have many `IndexTagValueRecord` records, each of which
 * will have one `TagRecord` association (where the tag value is stored).
 *
 * A related record, ``AppliedTagRecord`` exists for understanding how a tag is
 * applied to content. Each `AppliedTagRecord` has one `TagRecord` and a row
 * that joins all the contentId values that have that tag applied.
 */
struct IndexTagValueRecord: Codable, Hashable, Identifiable, Filterable, TagAssociation {
  var id: String = .randomIdentifier(24, prefix: "tagitem:")
  var tagId: String
  var contentId: ContentId
  var value: FilteringTag

  var asFilter: FilteringTag {
    self.value
  }
}

extension IndexTagValueRecord: TableRecord {
  static let databaseTableName = "app_content_tag_item_values"
}

extension IndexTagValueRecord: FetchableRecord {
  enum CodingKeys: String, CodingKey {
    case id, tagId, contentId, value
  }

  enum Columns: String, ColumnExpression {
    case id, tagId, contentId, value
  }

  static let associatedTag = hasOne(
    TagRecord.self,
    using: ForeignKey([TagRecord.Columns.id], to: [Columns.tagId])
  )

  static let associatedContent = hasOne(
    IndexRecord.self,
    using: ForeignKey([IndexRecord.Columns.id], to: [Columns.contentId])
  )

  /// Returns a Common Table Expression (CTE) containing the tag IDs associated with a given content ID.
  static func tagTable(for contentId: ContentId) -> CommonTableExpression<String> {
    Self.tagTable(for: [contentId])
  }
  
  /// Returns a Common Table Expression (CTE) containing the tag IDs associated with a given content IDs
  static func tagTable(for contentIds: [ContentId]) -> CommonTableExpression<String> {
    CommonTableExpression(
      named: "tagIds",
      request:
        IndexTagValueRecord
        .select(Columns.tagId)
        .filter(Columns.contentId.in(contentIds.values))
    )
  }
  
  static func forContent(_ contentId: ContentId) -> QueryInterfaceRequest<IndexTagValueRecord> {
    IndexTagValueRecord.filter(Columns.contentId.equals(contentId.value))
  }
  
  static func forContent(_ contentIds: [ContentId]) -> QueryInterfaceRequest<IndexTagValueRecord> {
    IndexTagValueRecord.filter(Columns.contentId.in(contentIds.values))
  }
}

extension DerivableRequest<IndexTagValueRecord> {

  typealias Columns = IndexTagValueRecord.Columns

  func forContent(_ contentId: ContentId) -> Self {
    filter(Columns.contentId.equals(contentId.value))
  }
  
  func forContent(_ contentIds: [ContentId]) -> Self {
    filter(Columns.contentId.in(contentIds.values))
  }

  func withTagDomain(_ domains: [FilteringTag.TagDomain]) -> Self {
    let tagTypes = domains.flatMap(\.domainSubtypes).uniqued()
    let associatedTag = IndexTagValueRecord.associatedTag

    return including(required: associatedTag.filter(TagRecord.Columns.tagType.in(tagTypes)))
  }

  func orderByTagValue(reversed: Bool = false) -> Self {
    if reversed {
      return order(TagRecord.Columns.tagValue.detached.desc)
    } else {
      return order(TagRecord.Columns.tagValue.detached.asc)
    }
  }
}

extension IndexTagValueRecord: DatabaseView {
  static let cteExpression = """
    SELECT
      tagitem.id as id,
      tagitem.tagId AS tagId,
      tagitem.contentId AS contentId,
      tag.filterValue AS value
    FROM 
      \(IndexTagRecord.databaseTableName) tagitem
    JOIN 
      \(TagRecord.databaseTableName) tag 
    ON 
      tagitem.tagId = tag.id
    """
}



