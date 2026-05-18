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
  
  static func tagMenu(when ctx: TagMenuContext) -> TagMenuConfig {
    switch ctx {
    case .taggedOn(let contentItem):
      return .buttons([
        [ .label(for: .refining), .filterIncluding, .filterExcluding ],
        [ .label(for: .broadening), .removeFrom(contentItem.id), .relabel(ctx) ],
        [ .label(for: .editable), .renameAll, .removeAll ],
        [ .searchFor, .copyText ],
      ])
      
    case .taggingContent:
      return .sections([ .refining, .editable, .searchable ])
      
    case .editingBrowseFilters:
      return .buttons([
        [ .label(for: .mutable), .changeDate, .relabel(ctx), .filterOff, .invert ],
        [ .label(for: .editable), .renameAll, .removeAll ],
        [ .searchFor, .copyText ]
      ])
    
    case .addingBrowseFilters:
      return .sections([ .refining, .editable, .searchable ])
      
    case .refiningSearchQuery:
      return .sections([ .refining, .searchable ])
      
    case .noContext:
      return .noMenu
    }
  }
}
