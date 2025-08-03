// created on 10/27/24 by robinsr

import CoreTransferable
import Foundation
import GRDB
import UniformTypeIdentifiers


fileprivate let PIPE = String("|")
fileprivate let PIPE_CHAR = Character("|")


enum FilteringTag: Identifiable, Equatable, Hashable, CustomStringConvertible {
  
  case tag(String)
  case artist(String)
  case creator(String)
  case contributor(String)
  case owner(String)
  case created(BoundedDate)
  case queue(String)
  case related(String)

  var id: String {
    "filteringtag:\(self.rawValue)".hashId
  }
  
  
  /**
   * The tag's domain (see ``FilteringTag/TagDomain``).
   */
  var domain: TagDomain {
    type.domain
  }
  
  
  /**
   * Returns an appropriate `SymbolIcon` icon for the tag based on its type/domain.
   */
  var icon: SymbolIcon {
    type.domain.icon
  }
  
  
  /**
   * Represents just the differentiating value of the tag, without capturing the type/domain or any other details
   */
  var value: String {
    switch self {
    case
        .tag(let value),
        .artist(let value),
        .creator(let value),
        .contributor(let value),
        .owner(let value),
        .queue(let value),
        .related(let value):
      return value
    case
        .created(let boundedDate):
      return boundedDate.rawValue
    }
  }

  
  /**
   * The tag's domain (see ``FilteringTag/TagType``).
   */
  var type: TagType {
    switch self {
    case .tag:
        return TagType.tag
    case .artist:
        return TagType.artist
    case .creator:
        return TagType.creator
    case .contributor:
        return TagType.contributor
    case .owner:
        return TagType.owner
    case .queue:
        return TagType.queue
    case .related:
        return TagType.related
    case .created(let date):
      switch date.bounds {
      case .before:
        return TagType.createdBefore
      case .onOrBefore:
        return TagType.createdOnOrBefore
      case .on:
        return TagType.createdOn
      case .onOrAfter:
        return TagType.createdOnOrAfter
      case .after:
        return TagType.createdAfter
      }
    }
  }

  /**
   * A human-readable description of the tag, which includes the type label and value.
   *
   * For example:
   * - "artist: Bob Dylan"
   * - "createdOn: 2021-10-29"
   * - "tag: rock"
   */
  var description: String {
    let label = self.type.description
    
    if label.isEmpty {
      return self.value
    }
    
    if let tagDate = self.date {
      return "\(label) \(DateFormatter.medium.string(from: tagDate))"
    }
    
    return "\(label): \(self.value)"
  }

  /**
   * Returns the relevant date for the tag if it is a date-related tag.
   */
  var date: Date? {
    switch self {
    case.created(let boundedDate):
      return boundedDate.date
    default:
      return nil
    }
  }
  
  /**
   * Returns the relevant `BoundedDate` for the tag if it is a date-related tag. A `BoundedDate` encapsulates both
   * a absoltue date value, and bounds to apply it to such as `before`, `on`, or `after`.
   */
  var boundedDate: BoundedDate? {
    switch self {
    case .created(let date):
      return date
    default:
      return nil
    }
  }
  
  /**
   * Creates a filtering tag based on the provided bounded date and tag domain (currently only `creation` is supported).
   */
  static func timeBounded(date bounds: BoundedDate, domain: TagDomain) -> FilteringTag? {
    switch domain {
    case .creation:
      return .created(bounds)
    default:
      return nil
    }
  }
  
  /**
   * Returns a new tag with the same differentiated value but of a different `TagType` (if possible).
   */
  func relabel(using tagType: TagType) -> FilteringTag {
    guard let newTag = tagType.makeTag(value) else {
      return self
    }
    return newTag
  }

  var truncated: String {
    value.truncated(toLength: 20)
  }
  
  var isSingleWord: Bool {
    value.charactersArray.none(matching: { $0.isWhitespace })
  }
  
  var isMultiWord: Bool {
    value.charactersArray.any(matching: { $0.isWhitespace })
  }
  
  var asSearchString: String {
    let termValue = isMultiWord ? value.wrap("{}") : value
    
    if type.oneOf(.tag, .artist, .creator, .owner, .contributor, .queue) {
      return "\(type.searchPrefix)\(termValue)"
    } else {
      return "{\(type.rawValue):\(value)}"
    }
  }
  
  var asSearchTerm: SearchTerm {
    SearchTerm(value: value, kind: type)
  }
  
  func filterAs(_ effect: FilteringTag.FilterEffect) -> FilteringTag.Filter {
    Filter(tag: self, effect: effect)
  }
  
  var asInclusive: FilteringTag.Filter {
    self.filterAs(.inclusive)
  }
  
  var asExcluding: FilteringTag.Filter {
    self.filterAs(.exclusive)
  }


    /// Character to separate tag type (label) from tag value. Values need to always be escaped.
  static let separator: String = PIPE
  static let separatorChar: Character = PIPE_CHAR
}


extension FilteringTag: RawRepresentable {
  typealias RawValue = String

  /**
   Initialize a FilteringTag from a string value, expected to be in the format
   of `type:value`, where `type` is a `TagType` and `value` is the tag value.
   Raw values that do not match this format will be treated as a tag with a
   type of `.tag`.

   Example:

   ```swift
   FilteringTag(rawValue: "artist|Bob Dylan")
   FilteringTag(rawValue: "tag|rock")
   FilteringTag(rawValue: "createdOn|2021-10-29T12:00:00Z")
   FilteringTag(rawValue: "inQueue|123")
   FilteringTag(rawValue: "ambient") // equivalent to  "tag:ambient"
   ```
   */
  init(rawValue str: String) {
    
    // Default to a generic tag if the rawValue is empty or does not contain a pipe
    self = FilteringTag.tag(str)
    
    let log = EnvContainer.shared.logger("FilteringTag")
    
    guard str.notEmpty else {
      log.emit(.error, "Invalid rawValue '\(str)'; Empty string")
      return
    }
    
    guard str.contains(PIPE_CHAR) else {
      log.emit(.warning, "Invalid rawValue '\(str)'; No separator")
      return
    }
    
    let pipeIndex = str.firstIndex(of: PIPE_CHAR)!
    let beforePipe = String(str[str.startIndex...str.index(before: pipeIndex)])
    let afterPipe = String(str[str.index(after: pipeIndex)...])
    
    guard
      let tagType = TagType(rawValue: beforePipe),
      let finalTag = tagType.makeTag(afterPipe)
    else {
      log.emit(.warning, "Invalid rawValue '\(str)'; Could not parse value/type components")
      return
    }
    
    self = finalTag
  }
  
  init(_ rawValue: String) {
    self.init(rawValue: rawValue)
  }

  /**
  Initialize a FilteringTag from a string value and a `TagType`.
  This is a convenience initializer that allows you to specify the type
  of the tag directly.

  Examples:

  ```swift
  FilteringTag(rawValue: "Bob Dylan", type: .artist)
  ```
  */
  init?(rawValue: String, type: TagType) {
    if let tag = type.makeTag(rawValue) {
      self = tag
    } else {
      return nil
    }
  }
  
  /**
   * The value that represents the FilteringTag in a raw format, without any formatting, escaping, or additional processing.
   *
   * This value can be used for serialization, storage, comparison, etc, and can be used to reconstruct the FilteringTag.
   */
  var rawValue: String {
    "\(type.rawValue)\(PIPE)\(value)"
  }
}


extension FilteringTag: DatabaseValueConvertible {
  public var databaseValue: DatabaseValue {
    DatabaseValue(value: self.rawValue)!.databaseValue
  }

  public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
    guard let stringValue = String.fromDatabaseValue(dbValue) else {
      return nil
    }
    return FilteringTag(rawValue: stringValue)
  }
}


extension FilteringTag: Codable {
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)
    
    self.init(rawValue: string)
  }
}


/**
 A collection of `FilteringTag` values conforming to `Transferable` to support drag and drop operations.
 */
struct FilteringTagSet: Equatable, Codable, Transferable {
  var values: [FilteringTag]

  init(_ values: [FilteringTag]) {
    self.values = values
  }

  init(_ value: FilteringTag) {
    self.init([value])
  }

  static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .filteringTag)
  }
}


extension FilteringTag: ExpressibleByStringLiteral {
  init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
}
