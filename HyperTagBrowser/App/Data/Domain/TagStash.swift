// created on 2/10/25 by robinsr


struct TagStash: Identifiable, Hashable {
  var id: StashId = .default
  var contents: Set<FilteringTag> = []
  
  var items: [FilteringTag] {
    Array(contents)
  }
}

extension TagStash {
  enum StashId: Identifiable, Hashable, Equatable {
    case id(String)
    
    var id: String {
      switch self {
      case .id(let id): return id
      }
    }
    
    static let `default` = StashId.id("default")
  }
}
