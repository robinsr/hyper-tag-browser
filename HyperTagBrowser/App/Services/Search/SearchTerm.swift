// created on 2/7/25 by robinsr

import Foundation


struct SearchTerm: Identifiable, Hashable, AttributeSearchable, CustomStringConvertible, Sendable {
  typealias Kind = FilteringTag.TagType
  
  let value: String
  let kind: Kind
  let comparison: SearchQuery.ComparisonOperator = .like
  let modifiers: Set<SearchTermModifier> = [.caseInsensitive]
  
  var id: String {
    "searchterm:\(searchPredicate.queryString.hashId)"
  }

  init(value: String, kind: Kind) {
    self.value = value
    self.kind = kind
  }
  
  init(_ str: String) {
    let (value, kind) = Matcher.matchOne(in: str)
    self.init(value: value, kind: kind)
  }
  
  /// Conforms to ``AttributeSearchable``
  var searchPredicate: any SearchQueryFragment {
    SearchQuery.Predicate(
      lhs: kind.csSearchableAttribute,
      rhs: value,
      compare: comparison,
      modifiers: modifiers
    )
  }

  var description: String {
    """
    SearchTerm(
      value: \(value)
      kind: \(kind)
      comparison: \(comparison.description)
      modifiers: \(modifiers.mdQueryModifiers)
      searchPredicate.queryString: \(searchPredicate.queryString)
      searchPredicate.nsPredicate: \(searchPredicate.nsPredicate)
    )
    """
  }
}



extension SearchTerm: Filterable {
  var asFilter: FilteringTag {
    self.kind.makeTag(value) ?? FilteringTag.related(value)
  }
}


extension SearchTerm: RawRepresentable {
  var rawValue: String {
    asFilter.asSearchString
  }
  
  init(rawValue: String) {
    self.init(rawValue)
  }
}

