// created on 9/19/24 by robinsr

import Foundation

typealias SortingComparator<Item: Any> = (Item, Item) -> Bool

enum SortConsideration {
  case top
  case bottom
}

/**
 * Defines the different sort options available for ``IndexRecord``s.
 */
enum SortType: String, CaseIterable, Identifiable, CustomStringConvertible, Codable {
  case nameAsc
  case nameDesc
  case createdAtAsc
  case createdAtDesc
  case sizeAsc
  case sizeDesc
  case tagCountAsc
  case tagCountDesc

  var id: Self { self }

  var description: String {
    switch self {
      case .nameAsc:
        return "Name A-Z"
      case .nameDesc:
        return "Name Z-A"
      case .createdAtAsc:
        return "Created At (oldest first)"
      case .createdAtDesc:
        return "Created At (newest first)"
      case .sizeAsc:
        return "File Size (Smallest First)"
      case .sizeDesc:
        return "File Size (Largest First)"
      case .tagCountDesc:
        return "Tag Count (Most First)"
      case .tagCountAsc:
        return "Tag Count (Fewest First)"
    }
  }

  static var initial: Self { .createdAtDesc }
}

extension SortType: SelectableOptions {

  static var asSelectables: [SelectOption<SortType>] {
    allCases.map {
      SelectOption(value: $0, label: $0.description)
    }
  }
}
