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
  enum TagType: String, Codable, CaseIterable {
    
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

   
    var displayString: String {
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
    
    var csSearchableAttribute: String {
      switch self {
      case .tag,
          .queue:
        return "keywords"
      case .artist,
          .creator,
          .contributor,
          .owner:
        return "contributors"
      case .related:
        return "displayName"
      case .createdBefore,
          .createdOnOrBefore,
          .createdOn,
          .createdOnOrAfter,
          .createdAfter:
        return "contentCreationDate"
      }
    }
    
    /**
     * The **Metadata Query Attribute Key** correspndonding to this TagType
     *
     * See [Common Metadata Attribute Keys](https://developer.apple.com/documentation/coreservices/file_metadata/mditem/common_metadata_attribute_keys)
     */
    var mdQueryAttribute: String {
      switch self {
      case .tag, 
          .queue:
        return "kMDItemKeywords"
      case .artist,
          .creator,
          .contributor,
          .owner:
        return "kMDItemContributors"
      case .related:
        return "kMDItemFSName"
      case .createdBefore,
          .createdOnOrBefore,
          .createdOn,
          .createdOnOrAfter,
          .createdAfter:
        return "kMDItemContentCreationDate"
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
        guard let dateFilter = DateFilter.before(value) else { return nil }
        return .created(dateFilter)
      case .createdOnOrBefore:
        guard let dateFilter = DateFilter.onOrBefore(value) else { return nil }
        return .created(dateFilter)
      case .createdOn:
        guard let dateFilter = DateFilter.onDate(value) else { return nil }
        return .created(dateFilter)
      case .createdOnOrAfter:
        guard let dateFilter = DateFilter.onOrAfter(value) else { return nil }
        return .created(dateFilter)
      case .createdAfter:
        guard let dateFilter = DateFilter.after(value) else { return nil }
        return .created(dateFilter)
      }
    }
  }
}


extension FilteringTag.TagType: CustomStringConvertible {
  var description: String {
    "FilteringTag.TagType.\(rawValue)"
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
