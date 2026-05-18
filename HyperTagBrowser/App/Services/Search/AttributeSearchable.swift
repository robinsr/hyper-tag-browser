// created on 12/23/25 by robinsr

import UniformTypeIdentifiers

/**
 * A protocol that allows conforming types to be used in Spotlight seach
 */
protocol AttributeSearchable {
  var searchPredicate: SearchQueryFragment { get }
}


extension UTType: AttributeSearchable {
  var searchPredicate: SearchQueryFragment {
    SearchQuery.Predicate(lhs: "contentType", rhs: identifier, compare: .equalTo)
  }
}

extension ContentTypeGroup: AttributeSearchable {
  var searchPredicate: SearchQueryFragment {
    SearchQuery.Compound(opr: .or, statements: filetypes.map(\.searchPredicate))
  }
}
