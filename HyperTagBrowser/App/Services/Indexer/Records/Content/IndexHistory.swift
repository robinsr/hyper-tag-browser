// created on 1/24/25 by robinsr

import Factory
import Foundation
import GRDB
import System
import UniformTypeIdentifiers


struct IndexHistory: Codable, Identifiable {
  var id: Int64?
  var timestamp: Date
  var fsStatus: Status
  var indexId: ContentId
  var indexType: UTType
  var columnName: String
  var newValue: String
  var oldValue: String
  
  enum Status: String, Codable, SQLSpecificExpressible {
    case synced, pending, failed
    
    static let databaseValueType: DatabaseValueConvertible.Type = String.self
  }
}

extension IndexHistory: FetchableRecord, PersistableRecord {
  enum CodingKeys: String, CodingKey {
    case id, timestamp, fsStatus, indexId, indexType, columnName, newValue, oldValue
  }
  
  enum Columns: String, ColumnExpression {
    case id, timestamp, fsStatus, indexId, indexType, columnName, newValue, oldValue
  }
  
  struct Selections {
    static func contentType(conformsTo uttype: UTType) -> SQLExpression {
      DatabaseFunctions.conformsTo.call(Columns.indexType, uttype)
    }
    
    static func status(_ status: Status) -> SQLExpression {
      Columns.fsStatus == status.rawValue
    }
    
    static func withinLast(_ value: Duration) -> SQLExpression {
      Columns.timestamp > Date.now.offset(subtracting: value)
    }
  }
}

extension DerivableRequest<IndexHistory> {
  typealias Selections = IndexHistory.Selections
  
  func withContentType(_ uttype: UTType) -> Self {
    filter(Selections.contentType(conformsTo: uttype))
  }
  
  func withStatus(_ status: IndexHistory.Status) -> Self {
    filter(Selections.status(status))
  }

  func within(_ value: Duration) -> Self {
    filter(Selections.withinLast(value))
  }
}



extension IndexHistory {
  
  private typealias IndxCol = IndexRecord.Columns
  
  var indexRenamed: Bool {
    IndxCol.name.name == columnName
  }
  
  var indexRelocated: Bool {
    IndxCol.location.name == columnName
  }
  
  var previous: String {
    oldValue.removingPercentEncoding ?? oldValue
  }
  
  var updated: String {
    newValue.removingPercentEncoding ?? newValue
  }
  
  var previousPath: FilePath {
    FilePath(previous)
  }
  
  var updatedPath: FilePath {
    FilePath(updated)
  }

  
  /// Returns an IndexRecord.Update corresponding to the opposite of the change that created the history record
  var revertUpdate: IndexRecord.Update? {
    if indexRelocated {
      return IndexRecord.Update.location(of: [indexId], with: previousPath)
    }
    
    if indexRenamed {
      return IndexRecord.Update.name(of: indexId, with: oldValue)
    }
    
    return nil
  }
  
  
  /// Returns a RenameTask describing how the filesystem operation should be performed
  func renameTask(for index: IndexRecord) -> RenameTask? {
    var renameTask: RenameTask? = nil
    
    if indexRelocated {
      renameTask = RenameTask(
        contentId: index.contentId,
        previous: previousPath.appending(index.name),
        updated: updatedPath.appending(index.name))
    }
    
    if indexRenamed {
      renameTask = RenameTask(
        contentId: index.contentId,
        previous: index.location.appending(previous),
        updated: index.location.appending(updated))
    }
    
    return renameTask
  }
}

extension IndexHistory: TableRecord {
  static let databaseTableName = "app_content_indices_history"
  
  static let index = hasOne(
    IndexRecord.self,
    using: ForeignKey([IndxCol.id], to: [Columns.indexId])
  )
}



extension IndexHistory {

  static let triggerColumns: [ColumnExpression] = [IndxCol.location, IndxCol.name]
  
  static func createTriggers(_ db: Database, recreate: Bool = false) throws {
    let thisTable = Self.databaseTableName
    let indexTable = IndexRecord.databaseTableName
    
    for column in triggerColumns.map(\.name) {
      if recreate {
        try db.execute(sql: "DROP TRIGGER IF EXISTS \(thisTable)_\(column)")
      }
      
      try db.execute(sql: """
          CREATE TRIGGER IF NOT EXISTS \(thisTable)_\(column)
          AFTER UPDATE OF \(column) ON \(indexTable)
          BEGIN
            INSERT INTO \(thisTable) (
              indexId, indexType, timestamp, columnName, newValue, oldValue, fsStatus
            )
            VALUES (
              NEW.id, NEW.type, datetime('now'), '\(column)', NEW.\(column), OLD.\(column), 'pending'
            );
          END
          """)
    }
  }
}
