// created on 2/10/25 by robinsr

import Foundation

enum AppSheet: Identifiable, Equatable, Hashable {

  /// An empty case; receiving `.none` indicates no sheets should be shown
  case none

  /// Displays properties of a ContentItem
  case contentDetailSheet(item: ContentItem)

  /// Contains search functionality
  case searchSheet(query: String?)

  /// Add, remove, replace the tags of a single ContentItem
  case editItemTagsSheet(item: ContentItem, tags: [FilteringTag])
  
  /// Add, remove, replace the tags of ContentItems as a group
  case editItemsTagsSheet(items: [ContentItem], tags: [FilteringTag])

  /// Just a TextView, to change the name of a ContentItem
  case renameContentSheet(item: ContentItem)

  /// Displays the `RenameTagSheetView` view
  case renameTagSheet(tag: FilteringTag, scope: BatchScope)

  /// Adjust the date of a date-based `FilteringTag`, and how it is applied to filtering
  case datePickerSheet(tag: FilteringTag)

  /// Create a new queue
  case createQueueSheet

  /// Displays a OutlineView-like UI of folders, to move files around
  case chooseDirectory(for: [ContentPointer])

  /// Displays a OutlineView-like UI of folders, to change the current working dir
  case changeDirectory

  /// Displays the UserProfile pane
  case userProfiles

  /// Displays a left/right split view of two images, to compare before saving
  case replaceImage(lhsURL: URL, rhsURL: URL)

  /// Displays the `SaveQuerySheetView`
  case newSavedQuerySheet(query: BrowseFilters)
  case updateSavedQuerySheet(record: SavedQueryRecord)

  /// Debug - Shows the the GRDB record for that ContentItem
  case debug_inspectContentItem(item: ContentItem)

  /// Debug - Shows the object created for spotlight indexing for that ContentItem
  case debug_inspectSpotlightData(item: ContentItem)

  /// Debug - Shows some metadata read from the ContentItem's file (e.g. EXIF data)
  case debug_inspectFileMetadata(item: ContentItem)

  var rawValue: String { self.id }

  var id: String {
    return self._case.rawValue
  }

  var presentation: SheetPresentation {
    switch self {
      case .chooseDirectory, .changeDirectory:
        return ChooseDirectoryForm.presentation
      case .contentDetailSheet:
        return ContentDetailSheet.presentation
      case .createQueueSheet:
        return CreateQueueView.presentation
      case .datePickerSheet:
        return AdjustFilterDateView.presentation
      case .renameContentSheet:
        return TextFieldSheet.presentation
      case .renameTagSheet:
        return RenameTagSheetView.presentation
      case .replaceImage:
        return ImageDiffSheetView.presentation
      case .newSavedQuerySheet, .updateSavedQuerySheet:
        return SaveQuerySheetView.presentation
      case .searchSheet:
        return SearchView.presentation
      case .editItemTagsSheet, .editItemsTagsSheet:
        return ListEditorSheetView.presentation
      case .userProfiles:
        return ProfileListSheetView.presentation
      case .debug_inspectContentItem,
        .debug_inspectSpotlightData,
        .debug_inspectFileMetadata:
        return SheetPresentation.code
      default:
      return SheetPresentation.modalSticky(controls: .close)
    }
  }

  /**
   * A set of cases that are used to access properties of the AppSheet. Useful for
   * switching on the type of sheet in a generic way, and for providing immutable
   * properties for the sheet.
   */
  enum Cases: String, CaseIterable, Hashable, Identifiable {
    case none
    
    case changeDirectory
    case chooseDirectory
    case contentDetailSheet
    case createQueueSheet
    case datePickerSheet
    case editItemTagsSheet
    case editItemsTagsSheet
    case newSavedQuerySheet
    case renameContentSheet
    case renameTagSheet
    case replaceImage
    case searchSheet
    case updateSavedQuerySheet
    case userProfiles
    
    case debug_inspectContentItem
    case debug_inspectSpotlightData
    case debug_inspectFileMetadata
    
    var id: String {
      self.rawValue
    }

    var title: String {
      switch self {
        case .contentDetailSheet:
          "File Details"
        case .searchSheet:
          "Search Sheet"
        case .editItemTagsSheet, .editItemsTagsSheet:
          "Edit Tags"
        case .renameTagSheet:
          "Rename Tag"
        case .renameContentSheet:
          "Rename File"
        case .datePickerSheet:
          "Adjust Date"
        case .createQueueSheet:
          "New Queue"
        case .chooseDirectory:
          "Relocate Items"
        case .changeDirectory:
          "Open Folder"
        case .userProfiles:
          "User Profiles"
        case .replaceImage:
          "Image Diff"
        case .newSavedQuerySheet:
          "Save Query"
        case .updateSavedQuerySheet:
          "Update Query"
        case .debug_inspectContentItem, .debug_inspectSpotlightData, .debug_inspectFileMetadata:
          "Debug Info"
        case .none:
          ""
      }
    }

    var keys: String {
      switch self {
        case .contentDetailSheet:
          "⌘I"
        case .searchSheet:
          "⌘/"
        case .editItemTagsSheet, .editItemsTagsSheet:
          "⌘T"
        case .renameTagSheet:
          "⌘R"
        case .renameContentSheet:
          "⌘R"
        case .createQueueSheet:
          "⌘N"
        case .chooseDirectory:
          "⌘D"
        case .changeDirectory:
          "⌘O"
        case .userProfiles:
          "⌃P"
        default:
          ""
      }
    }

    func shortcut(isShowing: Bool = false) -> KeyBinding {
      if keys.isEmpty {
        fatalError("Failed to create shortcut for \(self.rawValue.quoted) - no keys defined")
      }

      return KeyBinding(keys, named: "\(isShowing ? "Hide" : "Show") \(title)")
    }

    var shortcut: KeyBinding {
      if keys.isEmpty {
        fatalError("Failed to create shortcut for \(self.rawValue.quoted) - no keys defined")
      }

      return KeyBinding(keys, named: "\(title)")
    }
  }

  var _case: Cases {
    switch self {
      case .none: .none
      case .contentDetailSheet: .contentDetailSheet
      case .searchSheet: .searchSheet
      case .editItemTagsSheet: .editItemTagsSheet
      case .editItemsTagsSheet: .editItemsTagsSheet
      case .renameTagSheet: .renameTagSheet
      case .renameContentSheet: .renameContentSheet
      case .datePickerSheet: .datePickerSheet
      case .createQueueSheet: .createQueueSheet
      case .chooseDirectory: .chooseDirectory
      case .changeDirectory: .changeDirectory
      case .userProfiles: .userProfiles
      case .replaceImage: .replaceImage
      case .newSavedQuerySheet: .newSavedQuerySheet
      case .updateSavedQuerySheet: .updateSavedQuerySheet
      case .debug_inspectContentItem: .debug_inspectContentItem
      case .debug_inspectSpotlightData: .debug_inspectSpotlightData
      case .debug_inspectFileMetadata: .debug_inspectFileMetadata
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }

  enum ShowState: String {
    case isShowing
    case isHidden

  }
}
