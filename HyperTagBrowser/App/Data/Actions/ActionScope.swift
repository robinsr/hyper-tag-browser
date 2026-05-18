// created on 10/29/24 by robinsr


enum BatchScope: String, CustomStringConvertible, CaseIterable, Identifiable {
  case all        // .universal
  case visible    // .including(ids:<current filtering>)
  case hidden     // .excluding(ids:<current filtering>)
  case selected   // .including(ids:<manual list>)
  case unselected // .including(ids:<manual list>)
  
  var id: String { rawValue }
  
  var description: String {
    switch self {
    case .all: return "Everywhere"
    case .visible: return "Showing"
    case .hidden: return "All but showing"
    case .selected: return "Selected"
    case .unselected: return "Unselected"
    }
  }
}

extension BatchScope: SelectableOptions {
  static var asSelectables: [SelectOption<BatchScope>] {
    allCases.map { SelectOption(value: $0, label: $0.description) }
  }
}
