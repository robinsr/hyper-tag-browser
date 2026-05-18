// created on 4/23/25 by robinsr

enum ListEditorFocusable: Equatable {
  case none
  case prefix
  case itemId(String)

  var id: String {
    switch self {
    case .itemId(let itemId):
      return itemId
    case .none:
      return "scroll-to-none"
    case .prefix:
      return "scroll-to-top-command"
    }
  }
  
  var isItem: Bool {
    switch self {
    case .itemId(_): return true
    default: return false
    }
  }
  
  var isNeutral: Bool {
    self == .prefix
  }
  
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}
