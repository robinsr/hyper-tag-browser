// created on 6/1/25 by robinsr

import Foundation

extension NSComparisonPredicate.Operator {

  /**
   * The string representation of the search predicate operator.
   */
  public var token: String {
    switch self {
      case .lessThan: return "<"
      case .lessThanOrEqualTo: return "<="
      case .greaterThan: return ">"
      case .greaterThanOrEqualTo: return ">="
      case .equalTo: return "=="
      case .notEqualTo: return "=="
      case .matches: return "=~"
      case .like: return "=="
      case .beginsWith: return "=="
      case .endsWith: return "=="
      case .in: return "in"
      case .customSelector: return "customSelector"
      case .contains: return "contains"
      case .between: return "between"
      @unknown default:
        return ""
    }
  }

  /**
   * Returns the value portion for a search predicate statement.
   */
  public func statementValue<T: Comparable>(for value: T, modifiers mods: String = "") -> String {
    switch self {
      case .beginsWith:
        return "'\(value)*'\(mods)"
      case .endsWith:
        return "'*\(value)'\(mods)"
      case .contains:
        return "'*\(value)*'\(mods)"
      default:
        return "\(value)"
    }
  }

  /**
   * Returns a search predicate statement for the given attribute and value.
   *
   * - Parameters:
   *   - attribute: The attribute to compare against.
   *   - value: The value to compare with.
   *   - mods: Additional modifiers for the value (default is an empty string).
   *
   * - Returns: A string representing the search predicate statement.
   */
  public func statement<T: Comparable>(
    for attribute: String, value: T, mods: String = ""
  ) -> String {
    switch self {
      case .in:
        if let array = value as? [Any] {
          let joinedValues = array.map { "\($0)" }.joined(separator: ", ")
          return "\(attribute) IN (\(joinedValues))"
        }
        return ""
      case .customSelector:
        return "customSelector(\(attribute), \(value))"
      case .between:
        if let range = value as? ClosedRange<T> {
          return "\(attribute) between \(range.lowerBound) and \(range.upperBound)"
        }
        return ""
      default:
        return "\(attribute) \(token) \(statementValue(for: value, modifiers: mods))"
    }
  }
}
