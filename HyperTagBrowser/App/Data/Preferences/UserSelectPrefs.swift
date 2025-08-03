// created on 1/25/25 by robinsr

import Defaults


/**
 A `UserPrefSet` where the preference value can be one of a set of options
 */
struct UserSelectPrefs<T: Defaults.Serializable>: UserPrefSet {
  typealias Keys = ActiveUserProfile.CodingKeys
  
  var codingKey: Keys
  var options: [T]
  var defaultValue: T
  var label: String
  var helpText: String
  
  var id: String { codingKey.rawValue }
  

  init(key: Keys, options: [T], initial: T, label: String, help: String) {
    self.codingKey = key
    self.options = options
    self.defaultValue = initial
    self.label = label
    self.helpText = [help, "", "Default: **\(initial)**"].joined(separator: "\n")
  }
  
  var defaultsKey: Defaults.Key<T> {
    Defaults.Keys.userPref(codingKey, defaultValue)
  }
  
  static var photoGridItemLimit: UserSelectPrefs<Int> { .init(
    key: .photoGridItemLimit,
    options: [30, 100, 200, 400],
    initial: 100,
    label: "Number of grid items",
    help: "Limits the number of items displayed in the item grid. Lowering this number may improve performance.")
  }
  
  static var thumbnailQuality: UserSelectPrefs<ThumbnailQuality> { .init(
    key: .thumbnailQuality,
    options: ThumbnailQuality.allCases,
    initial: .high,
    label: "Thumbnail Quality",
    help: "Sets the size of content thumbnails. Lower quality may improve memory usage and performance.")
  }
  
  static var imageBuffFactor: UserSelectPrefs<ImageBuffingFactor> { .init(
    key: .imageBuffFactor,
    options: ImageBuffingFactor.allCases,
    initial: .high,
    label: "Image Buffing Factor",
    help: "Sets the image buffing factor for image loading. Higher values may improve image loading performance.")
  }
  
  static var sidebarPosition: UserSelectPrefs<SidebarChirality> { .init(
    key: .sidebarPosition,
    options: SidebarChirality.allCases,
    initial: .left,
    label: "Sidebar Position",
    help: "Sets the position of the sidebar in the main window.")
  }
  
  static var listEditorSuggestions: UserSelectPrefs<Int> { .init(
    key: .listEditorSuggestions,
    options: [4, 8, 12, 16, 20],
    initial: 4,
    label: "List Editor Suggestion Count",
    help: "Sets the number of suggestions to display in the list editor.")
  }
  
  static var searchMethod: UserSelectPrefs<SearchMethod> { .init(
    key: .searchMethod,
    options: SearchMethod.allCases,
    initial: .databaseQuery,
    label: "Search Method",
    help: "Sets the search API to invoke when using search functions in the app.")
  }
  
  static var preferredScheme: UserSelectPrefs<ColorSchemePreference> { .init(
    key: .preferredScheme,
    options: ColorSchemePreference.allCases,
    initial: .system,
    label: "Color Scheme Preference",
    help: "Sets the preferred color scheme for the app")
  }
}
