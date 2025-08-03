// created on 1/15/25 by robinsr

import GRDB

extension GRDB.Database {
  func createView(from table: DatabaseView.Type) throws {
    try self.create(
      view: table.databaseTableName,
      options: [.ifNotExists],
      as: SQLRequest(sql: table.cteExpression)
    )
  }
  
  func dropView(_ table: DatabaseView.Type) throws {
    try self.drop(view: table.databaseTableName)
  }
  
  func drop(table: TableRecord.Type) throws {
    try self.drop(table: table.databaseTableName)
  }
  
  func dropTable(named tableName: String) throws {
    try self.drop(table: tableName)
  }
  
  func createTempTable(for table: TableRecord.Type) throws -> String {
    let tableName = "temp_\(table.databaseTableName)"
    
    try self.execute(sql: """
    CREATE TABLE IF NOT EXISTS '\(tableName)' AS SELECT * FROM '\(table.databaseTableName)';
    """)
    
    return tableName
  }
  
  func copyTableContents(from sourceTable: String, to destTable: String) throws {
    try self.execute(sql: """
    INSERT INTO '\(destTable)' SELECT * FROM '\(sourceTable)';
    """)
  }
  
  func copyTableContents(from sourceTable: String, to destTable: String, columns: [String]) throws {
    try self.execute(sql: """
    INSERT INTO 
      '\(destTable)' (\(columns.joined(separator: ", "))) 
    SELECT 
      * FROM '\(sourceTable)'
    """)
  }
  
  func copyTableContents(
    from sourceTable: String,
    to destTable: String,
    columns: [String],
    selection: [String]
  ) throws {
    try self.execute(sql: """
    INSERT INTO 
      '\(destTable)' (\(columns.joined(separator: ", "))) 
    SELECT 
      \(selection.joined(separator: ", ")) FROM '\(sourceTable)'
    """)
  }
  
  func hasColumn(_ column: ColumnExpression, in table: TableRecord.Type) throws -> Bool {
    let columns = try self.columns(in: table.databaseTableName)
    return columns.contains { $0.name == column.name }
  }
  
  func hasColumn(named columnName: String, in table: TableRecord.Type) throws -> Bool {
    let columns = try self.columns(in: table.databaseTableName)
    return columns.contains { $0.name == columnName }
  }
  
  func hasTable(_ table: TableRecord.Type) throws -> Bool {
    try self.tableExists(table.databaseTableName)
  }
}
