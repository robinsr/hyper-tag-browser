// created on 1/20/25 by robinsr

import Foundation
import GRDB


extension FilteringTag {
  
  
  /**
   * Similar to `domain`, the `TagType` type represents a more specific classification of the tag. Some domains only
   * need one type, but some domains have multiple sub-types. For example, the `TagDomain.creation` domain has
   * multiple types that represent different ways of describing the creation date of a piece of content.
   *
   * The `TagType` type provides a way to classify the tag more specifically, and to provide additional
   * information about the tag, such as its label, search prefix, and whether it is a date-based tag.
   *
   * This is useful for filtering, searching, and displaying tags in a more meaningful way.
   *
   * For example, a tag of type `.createdOn` would indicate that the tag represents content created on a specific date,
   * while a tag of type `.createdBefore` would indicate that the tag represents content created before a specific date.
   *
   * This allows for more precise filtering and searching of content based on its creation date.
   *
   * The `TagType` also allows you to create new tags of the same type, which can be useful for mutating filters
   * already in use.
   */
  enum TagType: String, Codable, CaseIterable, CustomStringConvertible {
    
    case tag
    case artist
    case creator
    case contributor
    case owner
    case queue
    case related
    
    case createdBefore
    case createdOnOrBefore
    case createdOn
    case createdOnOrAfter
    case createdAfter

   
    var description: String {
      switch self {
      case .tag: ""
      case .artist: "Artist"
      case .creator: "Creator"
      case .contributor: "Contributor"
      case .owner: "Owner"
      case .queue: "In Queue"
      case .related: "Value"
      case .createdOn: "Created On"
      case .createdOnOrBefore: "Created On or Before"
      case .createdBefore: "Created Before"
      case .createdOnOrAfter: "Created On or After"
      case .createdAfter: "Created After"
      }
    }

    var domain: TagDomain {
      switch self {
      case
          .tag:
        return .descriptive
      case
          .artist,
          .creator,
          .contributor,
          .owner:
        return .attribution
      case
          .queue:
        return .queue
      case
          .related:
        return .unlabled
      case
          .createdBefore,
          .createdOnOrBefore,
          .createdOn,
          .createdOnOrAfter,
          .createdAfter:
        return .creation
      }
    }
    
    var searchPrefix: String {
      switch self {
      case .tag: return "#"
      case .artist: return "@"
      case .creator: return "!"
      case .owner: return "$"
      case .contributor: return "+"
      case .queue: return "~"
      default: return ""
      }
    }
    
    var fsAttribute: String {
      switch domain {
      case .descriptive: return "keyword"
      case .attribution: return "creator"
      case .creation: return "contentCreationDate"
      default: return "displayName"
      }
    }
    
    
    static func tagType(for prefix: String) -> TagType {
      switch prefix {
      case "#": return .tag
      case "@": return .artist
      case "!": return .creator
      case "$": return .owner
      case "+": return .contributor
      case "~": return .queue
      default: return .related
      }
    }
    

    func makeTag(_ value: String) -> FilteringTag? {
      switch self {
      case .tag:
        return .tag(value)
      case .artist:
        return .artist(value)
      case .creator:
        return .creator(value)
      case .contributor:
        return .contributor(value)
      case .owner:
        return .owner(value)
      case .queue:
        return .queue(value)
      case .related:
        return .related(value)
      case .createdBefore:
        guard let date = Date.parseDateString(value) else { return nil }
        return .created(BoundedDate(date: date, bounds: .before))
      case .createdOnOrBefore:
        guard let date = Date.parseDateString(value) else { return nil }
        return .created(BoundedDate(date: date, bounds: .onOrBefore))
      case .createdOn:
        guard let date = Date.parseDateString(value) else { return nil }
        return .created(BoundedDate(date: date, bounds: .on))
      case .createdOnOrAfter:
        guard let date = Date.parseDateString(value) else { return nil }
        return .created(BoundedDate(date: date, bounds: .onOrAfter))
      case .createdAfter:
        guard let date = Date.parseDateString(value) else { return nil }
        return .created(BoundedDate(date: date, bounds: .after))
      }
    }
  }
}


extension FilteringTag.TagType: DatabaseValueConvertible {
  public var databaseValue: DatabaseValue {
    DatabaseValue(value: self.rawValue)!.databaseValue
  }

  public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
    guard let stringValue = String.fromDatabaseValue(dbValue) else {
      return nil
    }
    return FilteringTag.TagType(rawValue: stringValue)
  }
}


extension FilteringTag.TagType: SelectableOptions  {
  static var asSelectables: [SelectOption<Self>] {
    Self.allCases.map { tagtype in
      SelectOption(
        value: tagtype,
        label: tagtype.rawValue.capitalized,
        icon: tagtype.domain.icon.systemName
      )
    }
  }
}
