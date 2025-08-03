// created on 1/15/25 by robinsr

import GRDB

/// Shorthand column definition methods
extension ColumnDefinition {
  /**
   * Shorthand for `.primaryKey(onConflict: .replace).unique(onConflict: .replace)`
   */
  @discardableResult
  func primary() -> Self {
    self.primaryKey(onConflict: .replace).unique(onConflict: .replace)
  }
  
  /**
   * Modifies the column to use the `CURRENT_TIMESTAMP` default value.
   */
  @discardableResult
  func timestamp() -> Self {
    self.notNull().defaults(sql: "CURRENT_TIMESTAMP")
  }
  
  /**
   * Modifies the column to reference a foreign key.
   */
  @discardableResult
  func references(
    _ column: ColumnExpression,
    in table: TableRecord.Type,
    onDelete delete: Database.ForeignKeyAction = .cascade,
    onUpdate update: Database.ForeignKeyAction = .cascade,
    isDeferred: Bool = true
  ) -> Self {
    self.references(column.name, in: table, onDelete: delete, onUpdate: update, isDeferred: isDeferred)
  }
  
  /**
   * Modifies the column to reference a foreign key.
   *
   * ## On Deferred Constraints
   *
   * > If a statement modifies the contents of the database so that an immediate foreign key constraint is
   * > in violation at the conclusion the statement, an exception is thrown and the effects of the statement are
   * > reverted. By contrast, if a statement modifies the contents of the database such that a deferred foreign key
   * > constraint is violated, the violation is not reported immediately. Deferred foreign key constraints are not
   * > checked until the transaction tries to COMMIT. For as long as the user has an open transaction, the database
   * > is allowed to exist in a state that violates any number of deferred foreign key constraints. However, COMMIT
   * > will fail as long as foreign key constraints remain in violation.
   * >
   * > [SQLite Foreign Key Support](https://www.sqlite.org/foreignkeys.html#fk_deferred)
   */
  @discardableResult
  func references(
    _ column: String,
    in table: TableRecord.Type,
    onDelete delete: Database.ForeignKeyAction = .cascade,
    onUpdate update: Database.ForeignKeyAction = .cascade,
    isDeferred: Bool = true
  ) -> Self {
    self.references(table.databaseTableName, column: column, onDelete: delete, onUpdate: update, deferred: isDeferred)
  }
}
