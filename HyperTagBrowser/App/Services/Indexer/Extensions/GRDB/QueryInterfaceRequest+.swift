// created on 3/3/25 by robinsr

import GRDB


extension QueryInterfaceRequest {
  
  public func toSQL(using db: Database, format: Bool = false) throws -> String {
    let stmt = try self.makePreparedRequest(db).statement
    
    let parts = "\(stmt)"
      .split(separator: "?")
      .map { $0.trimmingCharacters(in: .whitespaces) }
    
    let stringArgs = "\(stmt.arguments)"
      .dropFirst()
      .dropLast()
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
    
    
    var sql = ""
    var index = 0
    
    for part in parts {
      sql += String(part)
      
      if index < stringArgs.count {
        let arg = stringArgs[index]
        let nextPart = parts[safe: index + 1] ?? ""
        let lastPart = parts[safe: index - 1] ?? ""
        
        let noTrailing = nextPart.hasPrefix(")") || nextPart.hasPrefix(",")
        let noLeading = lastPart.lastWord == "("
        
        sql += "\(noLeading ? "" : " ")\(arg)\(noTrailing ? "" : " ")"
      }
      
      index += 1
    }
    
    if format {
      return SQLTraceFormatter(enabledTables: SchemaConfiguration.tableNames).formatEvent(string: sql)
    }
    
    return sql
  }
  
  public func toSQL(queue dbQueue: DatabaseQueue) throws -> String {
    try dbQueue.read { db in
      return try self.toSQL(using: db)
    }
  }
}
