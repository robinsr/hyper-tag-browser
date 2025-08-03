// created on 1/15/25 by robinsr

import GRDB

extension TableDefinition {
  
  
  /**
   * Adds `.column(...).primaryKey(onConflict: .ignore)` to table
   */
  @discardableResult
  func id(_ columnName: String, _ type: Database.ColumnType = .text) -> ColumnDefinition {
    self.column(columnName, type).primaryKey(onConflict: .ignore)
  }
  
  
  /**
   * Adds a datetime column to the table, defaulting to `CURRENT_TIMESTAMP`
   */
  @discardableResult
  func timestamp(_ columnName: String = "timestamp") -> ColumnDefinition {
    self.column(columnName, .datetime).notNull().timestamp()
  }
  
  /**
   * Adds a column to the table with a foreign key reference.
   */
  @discardableResult
  func column(_ name: String, ref: TableRecord.Type, refCol: String = "id") -> ColumnDefinition {
    self.column(name)
      .references(ref.databaseTableName, column: refCol, onDelete: .cascade)
      .notNull()
  }
  
  
  /**
   * Adds a column to the table with a foreign key reference.
   */
  @discardableResult
  func column(_ columnName: String, references column: ColumnExpression, in table: TableRecord.Type) -> ColumnDefinition {
    self.column(columnName).references(column, in: table)
  }
  
  
  /**
   * Adds a column to the table with a foreign key reference.
   */
  @discardableResult
  func column(_ columnName: String, references column: String = "id", in table: TableRecord.Type) -> ColumnDefinition {
    self.column(columnName).references(column, in: table)
  }
  
  
}
