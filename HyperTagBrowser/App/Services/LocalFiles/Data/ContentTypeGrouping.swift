// created on 5/24/25 by robinsr

import UniformTypeIdentifiers


//typealias ContentTypeGroup = AllowedFileType

enum ContentTypeGroup: String, Codable, CaseIterable, Identifiable {
  case folders
  case images
  case video
  case database
  
    /// Members of `nonUser` group are not user-facing and are used for internal operations.
  case nonUser
  
    /// Members of `user` group are user-facing and can be displayed in the UI.
  case user
  
    /// Represents all groups that are not internal. It's UTType would be `public.content`
  case content
  
    /// Represents all groups, including internal and user-facing.
  case all
  
    /// Represents a group that contains no content types.
  case empty
  
  private static var compositeTypes: [ContentTypeGroup] {
    [ContentTypeGroup.nonUser, .user, .content, .all, .empty]
  }
  
  
    /// Types cooresponding to ``/content``
  private static var contentSubsets: [ContentTypeGroup] {
    [ContentTypeGroup.images, .video]
    //[ContentTypeGroup.images, .audio, .video, .document, .archive, .text, .pdf, .code]
  }
  
    /// Types cooresponding to ``/internal``
  private static var internalSubsets: [ContentTypeGroup] {
    [ContentTypeGroup.database]
  }
  
    /// Types cooresponding to ``/user``
  private static var userSubset: [ContentTypeGroup] {
    [ContentTypeGroup.folders, .content]
  }
  
    /// Types cooresponding to ``/all``
  private static var allSubsets: [ContentTypeGroup] {
    [ContentTypeGroup.folders, .content, .user, .nonUser]
  }
  
    /// Subsets of ``/empty`` (which is empty)
  private static var emptyTypes: [ContentTypeGroup] {
   []
  }
  
  var id: String {
    self.rawValue
  }
  
  var title: String {
    self.rawValue.capitalized
  }
  
  var isCompsiteType: Bool {
    Self.compositeTypes.contains(self)
  }
  
  
  var expandedTypes: Set<UTType> {
      // Start the set with the filetypes of `self`, unless it is a composite type in which case it starts empty.
    let selfTypes = Set<UTType>(isCompsiteType ? [] : self.filetypes.asArray)
    
    return Self.allCases
      .filter {
          // Check that the subgroup is not the same as self, otherwise could cause infinite recursion.
        $0 != self
      }
      .filter {
          // Check that subgroup does not contain self, otherwise would cause infinite recursion.
        $0.contains(member: self) == false
      }
      .filter {
          // Finally, check that self actually contains the subgroup to allow merging of filetypes.
        self.contains(member: $0)
      }
      .reduce(into: selfTypes) { set, subgroup in
        set.formUnion(subgroup.filetypes.asArray)
      }
  }
  
  
  /**
   * The set of ContentTypeGroups that `self` is a super-set of.
   *
   * Examples
   * - `.document` is a superset of all document-like groups (pdfs, text files, archives, code).
   * - `.code` is a superset of `.database`
   * - The `.all` group is technically a superset of all content groups and content-types.
   */
  var subsets: [ContentTypeGroup] {
    switch self {
    case .user:
      return Self.userSubset
    case .nonUser:
      return Self.internalSubsets
    case .all:
      return Self.allSubsets
    case .content:
      return Self.contentSubsets
    case .empty:
      return Self.emptyTypes
    default:
      return []
    }
  }
  
  /**
   * The set of ContentTypeGroups that `self` is a subset of.
   */
  var supersets: [ContentTypeGroup] {
    Self.allCases.filter { $0.contains(member: self) }
  }
}



extension ContentTypeGroup: ContentTypeGrouping {
  func contains(member other: Self) -> Bool {
    self.subsets.contains(other)
  }
  
  func allows(filetype type: UTType) -> Bool {
    self.filetypes.any { type.conforms(to: $0) }
  }
  
  var filetypes: Set<UTType> {
    switch self {
    case .folders:
      return [ UTType.folder ]
    case .images:
      return [ UTType.image, .jpeg, .png, .tiff, .webP, .gif, .tiff, .heic, .heif, .heics ]
    case .video:
      return [ UTType.video, .mpeg4Movie, .appleProtectedMPEG4Video, .wav, .avi ]
    case .database:
      return [ UTType.sqlite, .sqlite3 ]
    case .empty:
      return []
    default:
      return self.expandedTypes
    }
  }

  
  var filetypeIdentifiers: [String] {
    self.filetypes.map { $0.identifier }
  }
}




extension ContentTypeGroup: Comparable {
  static func < (lhs: ContentTypeGroup, rhs: ContentTypeGroup) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}


extension ContentTypeGroup: CustomStringConvertible {
  
  
  var description: String {
    "\(self.id)[\(self.filetypeIdentifiers.joined(separator: ", "))]"
  }
  
   var legibleDescription: String {
     switch self {
     case .folders: return "Folders"
     case .images: return "Images"
     case .video: return "Video"
     case .database: return "Database Files"
     case .all: return "All Content Types"
     case .content: return "Content Types"
     case .empty: return "No Content Type"
     default: return "Unknown Content Type"
     }
   }
}

extension ContentTypeGroup: SelectableOptions {
  
  
  /**
   * Conforming to `SelectableOptions` as this allows this type to be used in pre-built UI components (see `SelectOption`. `MenuSelect`, etc).
   *
   * The issue is what set of ContentTypeGroups should be used as the selectable options? Currently using the `userSet`
   */
  static var asSelectables: [SelectOption<ContentTypeGroup>] {
    ContentTypeGroup.userSubset
      .map { SelectOption(value: $0, label: $0.title) }
  }
}


extension Sequence where Element == ContentTypeGroup {
  
  var filetypes: Set<UTType> {
    self.map(\.filetypes).reduce(into: Set<UTType>()) { result, types in
      result.formUnion(types)
    }
  }
  
  var typeIdentifiers: [String] {
    self.filetypes.map(\.identifier)
  }
  
  var groupIdentifiers: [String] {
    self.map { $0.id }
  }
}
