// created on 3/24/25 by robinsr

import GRDB

extension GRDB.ForeignKey {
  
  /**
   Creates a foreign key from the given other-table column to this table's `id` column.
   
   ```swift
   static let books = hasOne(Book.self, using: .toThis(from: Book.Columns.authorId))
   ```
   */
  static func toThis(from foreign: ColumnExpression,
                     to this: ColumnExpression = Column("id")) -> ForeignKey {
      self.init([foreign], to: [this])
  }
  
  /**
   Creates a foreign key from the given other-table column to this table's `id` column.
   
   ```swift
   static let books = hasOne(Book.self, using: .toThis(from: "authorId"))
   ```
   */
  static func toThis(from foreign: String, to this: String = "id") -> ForeignKey {
      self.init([foreign], to: [this])
  }
}
