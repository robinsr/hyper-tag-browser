// created on 2/3/25 by robinsr

extension FilteringTag {
  
  
  /**
   * Represents the broad category (aka domain) that this FilteringTag belongs to, and gives a good indication
   * of its purpose and usage. Eg,
   *
   * - `TagDomain.descriptive` describe some aspect of the target content
   * - `TagDomain.creation` describes when the content was created.
   * - `TagDomain.attribution` describes some aspect of the content's authorship or ownership.
   * - `TagDomain.queue` describes the content's position in a queue or playlist.
   * - `TagDomain.unlabeld` is a catch-all for tags that don't fit into any specific domain yet
   *
   *
   * Functionality derived from domain includes
   *
   * - Defines which icon can be applied to all FilteringTags in this domain
   * - Access to the domain's associated `TagType`s (sub-divisions of the domain that provide more specific categorization)
   * -
   */
  enum TagDomain: String, Codable, CaseIterable, CustomStringConvertible {
    
    case descriptive
    case attribution
    case queue
    case unlabled
    case creation
    
    
    var icon: SymbolIcon {
      switch self {
      case .descriptive: return .tag
      case .attribution: return .person
      case .queue: return .queue
      case .unlabled: return .unknown
      case .creation: return .calendar
      }
    }
    
    
    /**
     * Returns the list of high-specificity `TagType`s that are contained within this domain.
     */
    var domainSubtypes: [TagType] {
      TagType.allCases.filter { $0.domain == self }
    }
    
    var description: String {
      switch self {
      case .descriptive: "Described by"
      case .attribution: "Attributed to"
      case .queue: "Queued for"
      case .unlabled: "No Domain"
      case .creation: "Date Created"
      }
    }
  }
}
