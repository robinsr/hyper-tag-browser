// created on 10/26/26 by robinsr

import Foundation
import GRDB
import System

extension DBSnapshot {
  /// Counts rows in each table and reads the database and WAL file sizes. `path` is nil for
  /// in-memory databases, which report zero bytes.
  static func take(
    reader: any DatabaseReader,
    path: FilePath?,
    tables: [String] = SchemaConfiguration.baseTableNames,
    at date: Date = Date()
  ) throws -> DBSnapshot {
    let counts = try reader.read { db in
      try tables.reduce(into: [String: Int]()) { result, table in
        result[table] =
          try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table.quotedDatabaseIdentifier)")
          ?? 0
      }
    }

    return DBSnapshot(
      takenAt: date,
      fileBytes: fileSize(path),
      walBytes: fileSize(path.map { FilePath($0.string + "-wal") }),
      rowCounts: counts
    )
  }

  private static func fileSize(_ path: FilePath?) -> Int64 {
    guard let path, let attributes = try? FileManager.default.attributesOfItem(atPath: path.string)
    else { return 0 }

    return (attributes[.size] as? NSNumber)?.int64Value ?? 0
  }
}
