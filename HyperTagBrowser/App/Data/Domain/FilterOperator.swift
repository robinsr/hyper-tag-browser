// created on 9/19/24 by robinsr

import Foundation
import GRDB


typealias PredicateCompoundType = FilterOperator

enum FilterOperator: String, CustomStringConvertible, CaseIterable, Codable {
  case and = "all"
  case or = "any"
  
  var description: String { rawValue.capitalized }
  
  var compoundPredicateType: NSCompoundPredicate.LogicalType {
    switch self {
    case .and: return .and
    case .or: return .or
    }
  }
  
  var spotlightToken: String {
    switch self {
    case .and: return "&&"
    case .or: return "||"
    }
  }

  var sqlOperator: SQLExpression.AssociativeBinaryOperator {
    switch self {
    case .and: return .and
    case .or: return .or
    }
  }
  
  var inverse: FilterOperator {
    switch self {
    case .and: .or
    case .or: .and
    }
  }
  
  func toggle() -> FilterOperator {
    self.inverse
  }
}

extension FilterOperator: SelectableOptions {
  static var asSelectables: [SelectOption<FilterOperator>] {
    allCases.map { SelectOption(value: $0, label: $0.description) }
  }
}


extension Sequence where Element: StringProtocol {
  
  /**
   * Returns a string suitable for use in Spotlight queries, joining the elements with
   * the specified ``FilterOperator/spotlightToken``
   */
  func joinedForSpotlight(operator compoundType: FilterOperator) -> String {
    self.joined(separator: compoundType.spotlightToken.pad())
  }
}
