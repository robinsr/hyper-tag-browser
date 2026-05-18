// created on 5/24/25 by robinsr


/**
 * Defines the presentation modes for browsing files.
 *
 * The `BrowsePresentation` enum provides two modes:
 * - `grid`: Displays files in a grid layout, eg PhotoGrid.
 * - `table`: Displays files in a Finder-like table layout.
 */
enum BrowsePresentation: Equatable, CaseIterable {
  case grid
  case table
  
  var icon: SymbolIcon {
    switch self {
    case .grid: return .gridLarge
    case .table: return .listItems
    }
  }
  
  var shortcut: KeyBinding {
    switch self {
    case .grid: return .browseGridMode
    case .table: return .browseTableMode
    }
  }
}
