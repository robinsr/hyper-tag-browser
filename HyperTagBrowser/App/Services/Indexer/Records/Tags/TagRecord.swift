// created on 10/14/24 by robinsr

import Foundation
import GRDB
import GRDBQuery
import UniformTypeIdentifiers


/**
 * Defines the database type of a "tag"
 *
 * - Parameters:
 *    - tagValue: The differentiated value of the tag
 *    - tagType: The ``FilteringTag/TagType`` type of the tag (keyword/artist/queue/etc)
 *    - entryType: The ``TagRecord/EntryType`` type of the tag (alias/normal)
 *    - relatedId: For `alias` types, what the tag is an alias of
 *    -
 */
struct TagRecord: Codable, Identifiable, Hashable, Sendable {
  var id: String
  var tagValue: String
  var tagType: FilteringTag.TagType
  var entryType: TagRecord.EntryType
  var relatedId: TagRecord.ID?
  var filterValue: String?

  init(
    id: String = .randomIdentifier(24, prefix: "tag:"),
    tagValue: String = "",
    tagType: FilteringTag.TagType = .tag,
    type: TagRecord.EntryType = .normal,
  ) {
    self.id = id
    self.tagValue = tagValue.trimmed
    self.tagType = tagType
    self.entryType = type
  }
  
  init(_ filter: FilteringTag) {
    self.init(tagValue: filter.value, tagType: filter.type)
  }
  
  /// The `TagDomain` derived from the `TagType` of this record.
  var tagDomain: FilteringTag.TagDomain {
    tagType.domain
  }

  enum EntryType: String, Codable {
    case normal
    case alias
  }
}


extension TagRecord: Filterable {
  var asFilter: FilteringTag {
    FilteringTag(rawValue: tagValue, type: tagType) ?? .tag(tagValue)
  }
}


extension TagRecord: TableRecord {
  static let databaseTableName = "app_content_tags"
  
  static var databaseSelection: [SQLSelectable] {
    return [
      Columns.id,
      Columns.tagValue,
      Columns.tagType,
      Columns.entryType,
      Columns.relatedId,
      Columns.filterValue,
    ]
  }
}


extension TagRecord: FetchableRecord, PersistableRecord {
  enum CodingKeys: String, CodingKey {
    case id, tagValue, tagType, entryType, relatedId
  }

  public enum Columns: String, ColumnExpression {
    case id, tagValue, tagType, entryType, relatedId, filterValue
  }

  static let tagItems = hasMany(
    IndexTagRecord.self,
    using: ForeignKey([Column("tagId")], to: [Column("id")])
  )

  static let content = hasMany(
    IndexRecord.self,
    through: tagItems,
    using: IndexTagRecord.content
  )

  static let relatedTags = hasMany(
    TagRecord.self,
    using: ForeignKey([Columns.relatedId], to: [Columns.id])
  )

  struct Selections {
    static var filterValue: SQLExpression {
      DatabaseFunctions.textJoin.call(FilteringTag.separator, Columns.tagType, Columns.tagValue)
    }
  }
  
  func newAssociation(toContentId id: ContentId) -> IndexTagRecord {
    IndexTagRecord(tagId: self.id, contentId: id)
  }
}

extension DerivableRequest<TagRecord> {
  private typealias Columns = TagRecord.Columns
  private typealias ItemCols = IndexTagRecord.Columns

  func matching(filter: FilteringTag) -> Self {
    self.matching(filter: [filter])
  }

  func matching(filter filters: [FilteringTag]) -> Self {
    self.filter(filters.map(\.rawValue).contains(Columns.filterValue))
  }

  func excluding(filters: [FilteringTag]) -> Self {
    self.filter(!filters.map(\.rawValue).contains(Columns.filterValue))
  }

  func tagValueLike(_ value: String = "") -> Self {
    filter(Columns.tagValue.like(value
      .subSqlWildcards(for: /[^\w\d]+/)
      .asSqlLikeString(.matchEither))
    )
  }
  
  func inTagDomains(_ domains: [FilteringTag.TagDomain]) -> Self {
    filter(Columns.tagType.in(
      domains.flatMap(\.domainSubtypes).uniqued()
    ))
  }
}
