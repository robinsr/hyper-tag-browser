// created on 4/26/25 by robinsr

import Foundation
import GRDB

extension ColumnExpression {
  
  typealias LogicOperator = SQLExpression.AssociativeBinaryOperator
  
  /// Matches rows that equal ANY of the specified terms.
  func `in`<T: SQLExpressible>(_ values: [T]) -> SQLExpression {
    values.map(\.sqlExpression).contains(self.sqlExpression)
  }
  
  /// Matches rows that do NOT equal ANY of the specified terms.
  func not(in values: [SQLExpressible]) -> SQLExpression {
    !values.map(\.sqlExpression).contains(self.sqlExpression)
  }

  /// Matches rows that contain the specified term AT THE BEGINNING.
  func prefixed(like term: String) -> SQLExpression {
    self.like("\(term)%")
  }

  /// Matches rows that do NOT contain the specified term AT THE BEGINNING.
  func prefixed(unlike term: String) -> SQLExpression {
    !self.like("\(term)%")
  }

  /// Matches rows that contain the specified term AT THE END.
  func suffixed(like term: String) -> SQLExpression {
    self.like("%\(term)")
  }

  /// Matches rows that do NOT contain the specified term AT THE END.
  func suffixed(unlike term: String) -> SQLExpression {
    !self.like("%\(term)")
  }
  
  /// Matches rows that contain the specified term ANYWHERE in the string.
  func contains(like term: String) -> SQLExpression {
    self.like("%\(term)%")
  }
  
  /// Matches rows that do NOT contain the specified term ANYWHERE in the string.
  func contains(unlike term: String) -> SQLExpression {
    !self.like("%\(term)%")
  }
  
  /// Matches rows that equal the specified term exactly.
  func equals(_ term: String) -> SQLExpression {
    self == term
  }
  
  /// Matches rows that do NOT equal the specified term exactly.
  func notEquals(_ term: String) -> SQLExpression {
    self != term
  }
  
  /// Matches rows that equal ANY of the specified terms.
  func equals(anyOf terms: [SQLExpressible]) -> SQLExpression {
    terms.map(\.sqlExpression).contains(self.sqlExpression)
  }
  
  /// Matches rows that do NOT equal ANY of the specified terms.
  func equals(noneOf terms: [SQLExpressible]) -> SQLExpression {
    !terms.map(\.sqlExpression).contains(self.sqlExpression)
  }
  
  /// Matches rows that contain ANY of the specified terms ANYWHERE in the string.
  func like(anyOf terms: [String]) -> SQLExpression {
    terms
      .map { self.like("%\($0)%") }
      .joined(operator: .or)
  }
  
  /// Matches rows that contain ALL of the specified terms ANYWHERE in the string.
  func like(allOf terms: [String]) -> SQLExpression {
    terms
      .map { self.like("%\($0)%") }
      .joined(operator: .and)
  }
  
  /// Matches rows that do NOT contain ANY of the specified terms ANYWHERE in the string.
  func like(noneOf terms: [String]) -> SQLExpression {
    terms
      .map { !self.like("%\($0)%") }
      .joined(operator: .and)
  }
  
  func within(_ date: BoundedDate) -> SQLExpression {
    date.range.contains(GRDB.dateTime(self, .localTime))
  }
  
  func boundedBy(allOf bounds: [BoundedDate]) -> SQLExpression {
    if bounds.isEmpty {
      return .allowAll
    }
    
    return bounds
      .map { self.within($0) }
      .joined(operator: .and)
  }
  
  func boundedBy(anyOf bounds: [BoundedDate]) -> SQLExpression {
    if bounds.isEmpty {
      return .allowAll
    }
    
    return bounds
      .map { self.within($0) }
      .joined(operator: .or)
  }
}
