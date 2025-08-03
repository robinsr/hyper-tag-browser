// created on 10/14/24 by robinsr

import Foundation
import GRDB
import GRDBQuery
import UniformTypeIdentifiers

struct TagRecord: Codable, Identifiable, Hashable, Filterable {
  var id: String

  /// The differentiated value of the tag
  var tagValue: String

  /// Essentially the data-type of the tag, used for filtering.
  var tagType: FilteringTag.TagType

  /// The type of TagRecord entry. Distinguishes between normal tags and aliases.
  var entryType: TagRecord.EntryType

  /// If the entryType is `.alias`, this is the ID of the tag that this alias refers to.
  var relatedId: TagRecord.ID?

  /// The reconstructed filter value for this tag (value + type). A generated column (`.generatedAs(TagRecord.Selections.filterValue)`).
  var filterValue: String?

  /// The `TagDomain` derived from the `TagType` of this record.
  var tagDomain: FilteringTag.TagDomain {
    tagType.domain
  }

  @available(*, deprecated, renamed: "tagValue", message: "Use `tagValue` instead of `value`")
  var value: String {
    self.tagValue
  }

  @available(*, deprecated, renamed: "tagType", message: "Use `tagType` instead of `label`")
  var label: FilteringTag.TagType {
    self.tagType
  }

  init(
    id: String = .randomIdentifier(24, prefix: "tag:"),
    type: TagRecord.EntryType = .normal,
    value: String = "",
    label: FilteringTag.TagType = .tag
  ) {
    self.id = id
    self.tagValue = value.trimmed
    self.tagType = label
    self.entryType = type
  }

  var asFilter: FilteringTag {
    FilteringTag(rawValue: tagValue, type: tagType) ?? .tag(tagValue)
  }

  init(_ filter: FilteringTag) {
    self.init(value: filter.value, label: filter.type)
  }

  enum EntryType: String, Codable {
    case normal
    case alias
  }
}

extension TagRecord: TableRecord {
  static let databaseTableName = "app_content_tags"

  static let databaseSelection: [SQLSelectable] = [
    Columns.id,
    Columns.tagValue,
    Columns.tagType,
    Columns.entryType,
    Columns.relatedId,
    Columns.filterValue,
  ]
}

extension TagRecord: FetchableRecord, PersistableRecord {
  enum CodingKeys: String, CodingKey {
    case id, tagValue, tagType, entryType, relatedId
  }

  enum Columns: String, ColumnExpression {
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
      DatabaseFunctions.textJoin.call(FilteringTag.separator, Columns.tagValue, Columns.tagType)
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
    let scrubbedValue = value
      .subSqlWildcards(for: /[^\w\d]+/)
      .asSqlLikeString(.matchEither)
    
    print("tagValueLike: \(scrubbedValue)")
    
    return filter(Columns.tagValue.like(scrubbedValue))
  }
  
  func inTagDomains(_ domains: [FilteringTag.TagDomain]) -> Self {
    filter(Columns.tagType.in(
      domains.flatMap(\.domainSubtypes).uniqued()
    ))
  }
}
