// created on 3/4/25 by robinsr


extension FilteringTag {
  
  /**
   * While not named very descriptively, this struct models a `FilteringTag`
   * combined with an `FilterEffect`. It defines how a filter should be applied
   * to some filterable set of items.
   *
   * Same thing as Foundation's `Predicate`:
   *   - `Predicate.value` (`FilteringTag.Filter.tag`)
   *   - `Predicate.expression` (`FilteringTag.Filter.effect`)
   */
  struct Filter: Equatable, Hashable, Identifiable, Codable,
                 CustomStringConvertible, Filterable {
    
    // var value: FilteringTag
    var tag: FilteringTag
    var effect: FilteringTag.FilterEffect = .inclusive
    
    var id: String {
      "filteringtag.filter:\(tag.id)\(effect.rawValue)".hashId
    }
    
    var tagId: FilteringTag.ID { tag.id }
    
    var inverted: Self {
      Filter(tag: tag, effect: effect.inverted)
    }

    var description: String {
      "FilteringTag.Filter(\(tag.rawValue), \(effect.description))"
    }
    
    var asFilter: FilteringTag {
      self.tag
    }
    
    static func == (lhs: Filter, rhs: Filter) -> Bool {
      lhs.tag == rhs.tag && lhs.effect == rhs.effect
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(tag.rawValue)
      hasher.combine(effect.rawValue)
    }
  }
  
  
  
  /**
   * Defines the different effects a `FilteringTag` 
   */
  enum FilterEffect: String, Codable, CustomStringConvertible {
    
    /// A tag to match against
    case inclusive
    
    /// A tag to exclude matching against
    case exclusive
    
    
    var description: String {
      self.rawValue
    }
    
    var inverted: Self {
      switch self {
      case .inclusive: return .exclusive
      case .exclusive: return .inclusive
      }
    }
  }
  
  
  /**
   * Represents a set of ``FilteringTag/Filter`` filters
   */
  struct FilterGroup: Identifiable, Hashable {
    let id: String = .randomIdentifier(12)
    let name: String
    let items: [FilteringTag.Filter]
    
    var isEmpty: Bool {
      items.isEmpty
    }
    
    static func == (lhs: FilterGroup, rhs: FilterGroup) -> Bool {
      lhs.id == rhs.id &&
      lhs.items.allSatisfy { lhs.items.contains($0) } &&
      rhs.items.allSatisfy { rhs.items.contains($0) }
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      items.forEach { hasher.combine($0.hashValue) }
    }
  }
}
