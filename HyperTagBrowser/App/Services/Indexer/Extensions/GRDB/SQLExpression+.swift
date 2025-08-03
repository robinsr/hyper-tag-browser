// created on 3/4/25 by robinsr

import GRDB

extension SQLExpression {
  
  static let always: SQLExpression = true.sqlExpression
  static let any: SQLExpression = true.sqlExpression
  static let isTrue: SQLExpression = true.sqlExpression
  static let allowAll: SQLExpression = true.sqlExpression
  static let none: SQLExpression = false.sqlExpression
}


extension SQLSpecificExpressible {
  
  /**
   Returns an aliased column with the same name as the supplied column
   
   ```swift
   0.sqlExpression.forKey(Columns.someColumn)
   ```
   */
  func forKey(_ column: ColumnExpression) -> SQLSelection {
    forKey(column.name)
  }
  
  /**
   * Returns a NOT LIKE expression for the supplied pattern
   *
   * ```swift
   * let pattern = "foo%"
   * let expression = Column("bar").notLike(pattern)
   * ```
   */
  func notLike(_ pattern: String) -> SQLExpression {
    !self.like(pattern)
  }
}
