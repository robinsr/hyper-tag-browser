// created on 2/2/25 by robinsr


/**
 * Defines different logical groupings of `TagMenuButton` actions.
 *
 *  - refining: Actions that refine the current search or filter
 *  - broadening: Actions that broaden the current search or filter
 *  - editable: Actions that update the tag/filter's value, or what content the tag is assoicated with
 *  - searchable: Actions leading to a separate search workflow
 */
struct TagMenuSection: OptionSet, Hashable, CustomStringConvertible {
  let rawValue: Int
  
  static let refining = TagMenuSection(rawValue: 1 << 1)
  static let broadening = TagMenuSection(rawValue: 1 << 2)
  static let editable = TagMenuSection(rawValue: 1 << 3)
  static let searchable = TagMenuSection(rawValue: 1 << 4)
  static let mutable = TagMenuSection(rawValue: 1 << 5)

  static let empty = TagMenuSection(rawValue: 1 << 0)
  static let all = TagMenuSection(rawValue: 1 << 6)
  

  static let buttonMapping: [TagMenuSection: [TagMenuAction]] = [
    .refining: [.filterIncluding, .filterExcluding],
    .broadening: [.filterOff],
    .mutable: [.changeDate, .relabel(.whenAppliedAsQueryFilter), .invert],
    .editable: [.renameAll, .removeAll, .relabel(.whenAppliedAsContentTag)],
    .searchable: [.searchFor, .copyText]
  ]
  
  
  /**
   * All meaningful sections in the order they should appear in the menu
   */
  static let ordered: [TagMenuSection] = [.refining, .broadening, .mutable, .editable, .searchable]
  
  
  var description: String {
    switch self {
    case .refining: return "Add or Refine Filters"
    case .broadening: return "Remove Filters"
    case .mutable: return "Change Filtering Value"
    case .editable: return "Edit Tag's Properties"
    case .searchable: return ""
    default: return ""
    }
  }
  
  
  var menuButtons: [[TagMenuAction]] {
    if contains(.all) {
      return Self.ordered.map { $0.menuButtons.first! }
    }
    
    return Self.ordered.reduce(into: [[]]) { sections, section in
      guard contains(section) else { return }
      
      var buttons = Self.buttonMapping[section]!
      
      if let label = section.title {
        buttons.prepend(label)
      }
      
      sections.append(buttons)
    }
  }
  
  var title: TagMenuAction? {
    description.isEmpty ? nil : .text(description)
  }
}
