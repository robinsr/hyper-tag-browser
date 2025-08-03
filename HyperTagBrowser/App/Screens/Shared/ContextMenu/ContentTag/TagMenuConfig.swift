// created on 2/2/25 by robinsr


enum TagMenuConfig: Equatable, Hashable {
  case buttons([[TagMenuAction]])
  case sections(TagMenuSection)
  case sectionList([TagMenuSection])
  case noMenu
  
  var buttons: [TagMenuAction] {
    switch self {
    case .buttons(let buttons):
      return buttons
        .map { $0 + [.separator] }
        .flatMap { $0 }
        .dropLast()
    
    case .sections(let sections):
      return sections.menuButtons
        .map { $0 + [.separator] }
        .flatMap { $0 }
        .dropLast()
    
    case .sectionList(let sections):
      return sections
        .compactMap { $0.menuButtons.first }
        .flatMap { $0 }
      
    case .noMenu:
      return []
    }
  }
  
  
  //
  // MARK: - Pre-defined Configs
  //
  
  static var empty: Self {
    TagMenuConfig.noMenu
  }
  
  static var whenAppliedAsQueryFilter: Self {
    .buttons([
      [ .label(for: .mutable), .changeDate, .relabel(.whenAppliedAsQueryFilter), .filterOff, .invert ],
      [ .label(for: .editable), .renameAll, .removeAll ],
      [ .searchFor, .copyText ]
    ])
  }
  
  static var whenSuggestedAsQueryFilter: Self {
    .sections([.refining, .editable, .searchable])
  }
  
  static func whenAppliedAsContentTag(_ content: ContentItem) -> Self {
    .whenAppliedAsContentTag(content.pointer)
  }
  
  static func whenAppliedAsContentTag(_ pointer: ContentPointer) -> Self {
    .buttons([
      [ .label(for: .refining), .filterIncluding, .filterExcluding ],
      [ .label(for: .broadening), .removeFrom(pointer), .relabel(.whenAppliedAsContentTag) ],
      [ .label(for: .editable), .renameAll, .removeAll ],
      [ .searchFor, .copyText ],
    ])
  }
  
  static var whenSuggestedAsContentTag: Self {
    .sections([.refining, .editable, .searchable])
  }
  
  static var whenSuggestedDuringSearch: Self {
    .sections([.refining, .searchable])
  }
}
