// created on 6/1/25 by robinsr

import Foundation
import UniformTypeIdentifiers



/**
 * Conformance to SearchQueryFragment allows an object to be used in a search query
 *
 * - `queryString`: The string representation of the search query
 * - `nsPredicate`: The NSPredicate representation of the search query
 */
protocol SearchQueryFragment {
  var queryString: String { get }
  var nsPredicate: NSPredicate { get }
}


extension SearchQuery {
  /**
   * A container for a single comparison operation, typically between a file attribute type and a value
   */
  struct Predicate: SearchQueryFragment {
    var lhs: String
    var rhs: String
    var compare: ComparisonOperator = .equalTo

    var queryString: String {
      compare.statement(for: lhs, value: rhs)
    }

    var nsPredicate: NSPredicate {
      NSComparisonPredicate(
        leftExpression: .init(format: "%K", lhs),
        rightExpression: .init(format: "%@", rhs),
        modifier: .direct,
        type: compare)
    }
  }

  /**
   * A container for a set of QueryPredicate objects, combined with a logical operator
   */
  struct Compound: SearchQueryFragment {
    var opr: PredicateCompoundType
    var statements: [(any SearchQueryFragment)?]

    var queryString: String {
      statements
        .compactMap(\.?.queryString)
        .map{ $0.wrap(.ifAbsent("()")) }
        .joinedForSpotlight(operator: opr)
        .wrap(.ifAbsent("()"))
    }

    var nsPredicate: NSPredicate {
      NSCompoundPredicate(
        type: opr.compoundPredicateType,
        subpredicates: statements.compactMap(\.?.nsPredicate)
      )
    }
  }
}


/**
 * Conformance to SearchableContentAttribute allows an object to be used as a search attribute.
 */
protocol SearchableContentAttribute {
  var searchPredicate: SearchQueryFragment { get }
}


extension UTType: SearchableContentAttribute {
  var searchPredicate: SearchQueryFragment {
    SearchQuery.Predicate(lhs: "contentType", rhs: identifier, compare: .equalTo)
  }
}

extension ContentTypeGroup: SearchableContentAttribute {
  var searchPredicate: SearchQueryFragment {
    SearchQuery.Compound(opr: .or, statements: filetypes.map(\.searchPredicate))
  }
}
