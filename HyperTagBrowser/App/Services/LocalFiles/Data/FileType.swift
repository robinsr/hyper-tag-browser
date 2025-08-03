// created on 11/17/24 by robinsr

import UniformTypeIdentifiers



protocol ContentTypeGrouping {
  // func contains(filetype: UTType) -> Bool
  func allows(filetype type: UTType) -> Bool
  func contains(member: Self) -> Bool
  
  
  /**
   * Defines the non-grouped file types that this grouping represents.
   *
   * Can be base classes in the hierarchy, eg `public.image`
   * Or can be more specific classes, such as those that map to mimeTypes, eg `public.jpeg`
   *
   * If the filetypes set contains broader types, such as `public.image`, then there;s no need to include more specific types like `public.jpeg` or `public.png`.
   *
   * Some groups are going to be entirely composed of specific file types, such as `public.jpeg`, `public.png`, etc.
   * And other groups will have zero file types, such as `.all`, which is a composite type that references other groupings
   */
  var filetypes: Set<UTType> { get }
}


@available(*, deprecated, message: "Use `ContentTypeGroup` instead")
struct AllowedFileTypes: OptionSet, Hashable, CaseIterable, Codable {
  let rawValue: Int
  
    /// Folder types
  static let folders = AllowedFileTypes(rawValue: 1 << 0)
  
    /// Content types
  static let images = AllowedFileTypes(rawValue: 1 << 1)
  static let audio = AllowedFileTypes(rawValue: 1 << 2)
  static let video = AllowedFileTypes(rawValue: 1 << 3)
  static let document = AllowedFileTypes(rawValue: 1 << 4)
  static let archive = AllowedFileTypes(rawValue: 1 << 5)
  static let text = AllowedFileTypes(rawValue: 1 << 6)
  static let code = AllowedFileTypes(rawValue: 1 << 7)
  
  
    /// SQLite database files
  static let sqlite = AllowedFileTypes(rawValue: 1 << 8)
  
    /// Identifies a UTType not supported by the app
  static let disallowed = AllowedFileTypes(rawValue: 1 << 9)
  
    // conform to CaseIterable
  static let allCases: [AllowedFileTypes] = [
    .folders, .images, .audio, .video, .document, .archive, .text, .code, .sqlite
  ]
  
    //MARK: - Composite Options
  
    /// Content types
  static let content: AllowedFileTypes = [.images, .audio, .video, .document, .archive, .text, .code]
  
    /// All file types recognized by the app
  static let all: AllowedFileTypes = [.content, .folders, .sqlite]
  
  
    //MARK: - Properties

  
  var expandedTypes: Set<UTType> {
    let allGroupings = Self.allCases
    
    return allGroupings.reduce(into: Set<UTType>()) { set, subgroup in
      if self.contains(member: subgroup) {
        set.formUnion(subgroup.filetypes.asArray)
      }
    }
  }

  
  var dialogmessage: String {
    switch self {
    case .folders: return "Choose a folder"
    case .images: return "Choose images"
    case .sqlite: return "Choose database file"
    default: return "Choose any"
    }
  }
  
  var name: String {
    switch self {
    case .all: return "All"
    case .folders: return "Folders"
    case .content: return "Content"
    case .images: return "Images"
    case .audio: return "Audio"
    case .video: return "Video"
    case .document: return "Documents"
    case .archive: return "Archives"
    case .text: return "Text"
    case .code: return "Code"
    case .sqlite: return "SQLite"
    case .disallowed: return "Disallowed"
    default: return "Other/CompositeType"
    }
  }
  
  
  var thumbnailScale: Double {
    switch self {
    case .images: return 1.05
    case .folders: return 0.75
    default: return 1.0
    }
  }
  
  var thumbnailSize: CGSize {
    CGSize(widthHeight: Constants.maxTileSize) //(Constants.maxTileSize / 4) - 50)
      .scaled(byFactor: CGFloat(thumbnailScale))
      .rounded(.down)
  }

  static func forURL(_ url: URL) -> AllowedFileTypes {
    if url.isDirectory {
      return .folders
    }
    
    guard let typeFromURL = UTType(filenameExtension: url.pathExtension) else {
      return .disallowed
    }
    
    for group in AllowedFileTypes.allCases {
      if group.allows(filetype: typeFromURL) {
        return group
      }
    }
    
    return .disallowed
  }
  
  @available(*, deprecated, message: "Use `.filetypes` on instance of `AllowedFileTypes` instead")
  static func types(for grouping: Self) -> [UTType] {
    grouping.filetypes.asArray
  }
}


extension AllowedFileTypes: ContentTypeGrouping {
  
  func allows(filetype type: UTType) -> Bool {
    self.filetypes.any { type.conforms(to: $0) }
  }
  
  
  func contains(member group: Self) -> Bool {
    // For the OptionSet version of AllowedFileTypes, checking group membership is straightforward (`.contains` provided by OptionSet protocol)
    return self.contains(group)
  }
  
  var filetypes: Set<UTType> {
    switch self {
    case .images: return [
      UTType.image
    ]
    case .audio: return [
      UTType.audio
    ]
    case .video: return [
      UTType.video
    ]
    case .document: return [
      UTType.text, UTType.plainText
    ]
    case .archive: return [
      UTType.archive
    ]
    case .text: return [
      UTType.text
    ]
    case .code: return [
      UTType.sourceCode
    ]
    case .sqlite: return [
      UTType.sqlite , UTType.sqlite3
    ]
    case .folders: return [
      UTType.folder
    ]
    case .disallowed: return []
    default:
      return self.expandedTypes
    }
  }
  
  var filetypeIdentifiers: [String] {
    self.filetypes.map { $0.identifier }
  }
}



extension AllowedFileTypes: CustomStringConvertible {
  var description: String {
    ".\(name.lowercased())[\(filetypeIdentifiers.joined(separator: ", "))]"
  }
}


extension AllowedFileTypes: CustomDebugStringConvertible {
  var debugDescription: String {
    "AllowedFileTypes(rawValue: \(rawValue.nonzeroBitCount); \(description))"
  }
}



extension Sequence where Element == AllowedFileTypes {
  var filetypes: [UTType] {
    self.flatMap{ $0.filetypes }.asSet.asArray
  }
}
