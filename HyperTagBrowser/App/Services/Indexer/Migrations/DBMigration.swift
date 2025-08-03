// created on 10/24/24 by robinsr

import AppKit
import GRDB
import Foundation


struct MigrationVersions {
  
  enum Version: String, CaseIterable {
    case initialDatabaseSchema = "V1"
    case jan_14_2025_add_tagrecord_label = "jan_14_2025"
    case jan_15_2025_add_foreign_keys_with_cascade_delete_to_indextagrecord_queueitemrecord = "jan_15_2025"
    case jan_16_2025_queuerecord_tagname
    case jan_24_2025_create_indexhistory
    case jan_24_2025_add_indexhistory_location_trigger
    case jan_31_2025_add_tagrecord_filtervalue
    case feb_11_2025_history_fsstatus
    case feb_22_2025_add_relatedId_to_tagrecord
    case mar_19_2025_history_content_type
    case apr_10_2025_add_indexrecord_filesize
    case apr_11_2025_convert_urls_to_filepath
    case apr_11_2025_add_indexrecord_timestamp
    case may_25_2025_create_savedqueries_table
    case jun_1_2025_rename_tablerecord_columns
    case jun_1_2025_migrate_indexrecord_thumbnails
    case jun_4_2025_reomve_indexrecord_thumbnail
    case jun_9_2025_add_bookmarkrecord_contentId
    case aug_2_2025_add_indexes_location_type_size_created_visibility
    case none
    
    static var allVersions: [Version] {
      self.allCases.filter { $0 != .none }
    }
  }
  
  enum EvaluationResult {
    case unmigrated
    case migrated
    case skip
  }
  
  struct Config {
    var state: Readiness = .ready
    let version: MigrationVersions.Version
    let description: String
    var checkFn: (Database) throws -> (EvaluationResult) = { _ in .unmigrated }
    let migrateFn: (Database) throws -> ()
    
    func migrate(_ db: Database) throws {
      try self.migrateFn(db)
    }
    
    func snapshotPath(dir: URL) -> URL {
      dir.appendingPathComponent("\(version.rawValue).sqlite")
    }
    
    enum Readiness {
      case ready, pending, testing
    }
  }
  
  static func get(version: Version) -> Config? {
    migrations.first { $0.version == version }
  }
  
  static let migrations: [Config] = [
    Config(
      version: .initialDatabaseSchema,
      description: """
      Initial setup of database
      """,
      migrateFn: { db in
        try db.create(table: IndexRecord.databaseTableName) { table in
          table.id("id")
          
          table.column("timestamp",  .datetime).defaults(sql: "CURRENT_TIMESTAMP")
          table.column("name",       .text).notNull()
          table.column("location",   .text).notNull()
          table.column("type",       .text).notNull()
          table.column("size",       .numeric).notNull().defaults(to: 0)
          table.column("created",    .datetime).notNull()
          table.column("comment",    .text).notNull()
          table.column("modified",   .datetime).notNull().defaults(to: Date.now)
          table.column("volume",     .text).notNull().defaults(to: "Macintosh HD")
          table.column("visibility", .text).notNull().defaults(to: ContentItemVisibility.normal.rawValue)
        }
        
        
        try db.create(table: TagRecord.databaseTableName) { table in
          table.id("id")
          
          table.column("type",        .text).notNull().defaults(to: TagRecord.EntryType.normal.rawValue)
          table.column("label",       .text).notNull().defaults(to: FilteringTag.TagType.tag.rawValue)
          table.column("value",       .text).notNull()
          table.column("filterValue", .text).generatedAs(TagRecord.Selections.filterValue)
          table.column("relatedId",   .text).references(TagRecord.databaseTableName, column: "id", onDelete: .cascade)
          
          table.uniqueKey(["label", "value"], onConflict: .ignore)
        }
        
        
        try db.create(table: BookmarkRecord.databaseTableName) { table in
          table.id("id")
          
          table.column("created",  .date).notNull()
          table.column("contentId", .text).references(IndexRecord.databaseTableName, column: "id", onDelete: .cascade)
        }
        
        
        try db.create(table: QueueRecord.databaseTableName) { table in
          table.id("id")
          
          table.column("name",    .text).notNull()
          table.column("created", .datetime).notNull()
          table.column("tagName", .text).generatedAs(QueueRecord.Selections.filterValue)
        }
        
        
        try db.create(table: IndexTagRecord.databaseTableName) { table in
          table.id("id")
          
          table.column("tagId",     references: TagRecord.Columns.id,   in: TagRecord.self).notNull()
          table.column("contentId", references: IndexRecord.Columns.id, in: IndexRecord.self).notNull()
          
          table.uniqueKey(["tagId", "contentId"], onConflict: .fail)
        }
        
        
        try db.create(table: QueueItemRecord.databaseTableName) { table in
          table.id("id")
          
          table.column("created",   .datetime).notNull()
          table.column("completed", .boolean).notNull()
          
          table.column("queueId",   references: QueueRecord.Columns.id, in: QueueRecord.self).notNull()
          table.column("contentId", references: IndexRecord.Columns.id, in: IndexRecord.self).notNull()
          
          table.uniqueKey(["tagId", "contentId"], onConflict: .ignore)
        }
        
        try SavedQueryRecord.createTable(db)
      }),
    
    Config(
      version: .jan_14_2025_add_tagrecord_label,
      description: """
        - Added col `TagRecord.label` (default: "tag") (later renamed to `tagType`)
      """,
      checkFn: { db in
        try db.hasColumn(TagRecord.Columns.tagType, in: TagRecord.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: "app_content_tags") { table in
          table.add(column: "label", .text).defaults(to: FilteringTag.TagType.tag.rawValue)
        }
      }),
    
    Config(
      state: .pending,
      version: .jan_15_2025_add_foreign_keys_with_cascade_delete_to_indextagrecord_queueitemrecord,
      description: """
        - Removes previously created views
        - Adds ON DELETE CASCADE to `IndexTagRecord.contentId`
        - Adds ON DELETE CASCADE to `QueueItemRecord.contentId`
        - Recreates views
      """,
      migrateFn: { db in
        try db.dropView(IndexTagValueRecord.self);
        try db.dropView(TagstringRecord.self);
          //try db.dropView(AppliedTagRecord.self);
        
        var tmp = try db.createTempTable(for: IndexTagRecord.self)
        
        try db.drop(table: IndexTagRecord.self)
        
        try db.create(table: IndexTagRecord.databaseTableName) { table in
          table.column("id", .text)
          
          table.column("tagId",     references: TagRecord.Columns.id,   in: TagRecord.self).notNull()
          table.column("contentId", references: IndexRecord.Columns.id, in: IndexRecord.self).notNull()
          
          table.uniqueKey(["tagId", "contentId"], onConflict: .ignore)
        }
        
        try db.copyTableContents(
          from: tmp,
          to: IndexTagRecord.databaseTableName,
          columns: ["tagId", "contentId", "id"]
        )
        try db.dropTable(named: tmp)
        
          // ---
        
        tmp = try db.createTempTable(for: QueueItemRecord.self)
        
        try db.drop(table: QueueItemRecord.self)
        
        try db.create(table: QueueItemRecord.databaseTableName) { table in
          table.id("id")
          table.column("created",   .datetime).notNull()
          table.column("completed", .boolean).notNull()
          table.column("queueId",     ref: QueueRecord.self)
          table.column("contentId",   ref: IndexRecord.self)
        }
        
        try db.copyTableContents(
          from: tmp,
          to: QueueItemRecord.databaseTableName,
          columns: ["id", "queueId", "contentId", "created", "completed"]
        )
        
        try db.dropTable(named: tmp)
      }),
    
    
    Config(
      version: .jan_16_2025_queuerecord_tagname,
      description: """
        - Adds col `QueueRecord.tagName`
      """,
      checkFn: { db in
        try db.hasColumn(QueueRecord.Columns.tagName, in: QueueRecord.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: QueueRecord.databaseTableName) { table in
          table.add(column: QueueRecord.Columns.tagName.name, .text).generatedAs(QueueRecord.Selections.filterValue)
        }
      }),

    
    Config(
      version: .jan_24_2025_create_indexhistory,
      description: """
        - Adds table `IndexHistory`
      """,
      checkFn: { db in
        try db.hasTable(IndexHistory.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        let histCols = IndexHistory.Columns.self
        let fsStatus = IndexHistory.Status.self
        
        try db.create(table: IndexHistory.databaseTableName) { table in
          
          table.autoIncrementedPrimaryKey(histCols.id.name)
          table.timestamp(histCols.timestamp.name)
          
          table.column(histCols.indexId.name,    .text).notNull().indexed()
          table.column(histCols.indexType.name,  .text)
          table.column(histCols.fsStatus.name,   .text).notNull().defaults(to: fsStatus.pending.rawValue)
          table.column(histCols.columnName.name, .text).notNull()
          table.column(histCols.newValue.name,   .text).notNull()
          table.column(histCols.oldValue.name,   .text).notNull()
        }
      }),
    
    Config(
      version: .jan_31_2025_add_tagrecord_filtervalue,
      description: """
        - Adds column `TagRecord.filterValue` as concat(value, label)
      """,
      checkFn: { db in
        try db.hasColumn(TagRecord.Columns.filterValue, in: TagRecord.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: TagRecord.databaseTableName) { table in
          table.add(column: TagRecord.Columns.filterValue.name, .text).generatedAs(TagRecord.Selections.filterValue)
        }
      }),
    
    Config(
      version: .feb_11_2025_history_fsstatus,
      description: """
      Adds `IndexHistory.fsStatus` (default 'pending')
      """,
      checkFn: { db in
        try db.hasColumn(IndexHistory.Columns.fsStatus, in: IndexHistory.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: IndexHistory.databaseTableName) { table in
          table.add(column: IndexHistory.Columns.fsStatus.name, .text)
            .defaults(to: IndexHistory.Status.pending.rawValue)
        }
      }),
    
    Config(
      version: .mar_19_2025_history_content_type,
      description: """
        - Adds col `IndexHistory.indexType` (default null)
      """,
      checkFn: { db in
        try db.hasColumn(IndexHistory.Columns.indexType, in: IndexHistory.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: IndexHistory.databaseTableName) { table in
          table.add(column: "indexType", .text)
        }
      }),
    
    Config(
      version: .feb_22_2025_add_relatedId_to_tagrecord,
      description: """
        - Adds col `TagRecord.relatedId` (default null)
      """,
      checkFn: { db in
        try db.hasColumn(TagRecord.Columns.relatedId, in: TagRecord.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: TagRecord.databaseTableName) { table in
          table.add(column: "relatedId", .text)
            .references(TagRecord.databaseTableName, column: TagRecord.Columns.id.name, onDelete: .cascade)
        }
      }),
    
    Config(
      version: .apr_10_2025_add_indexrecord_filesize,
      description: """
        - Adds col `IndexRecord.size` (default 0)
      """,
      checkFn: { db in
        try db.hasColumn(IndexRecord.Columns.size, in: IndexRecord.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: IndexRecord.databaseTableName) { table in
          table.add(column: "size", .numeric).notNull().defaults(to: 0)
        }
        
        try db.execute(literal: """
          UPDATE 
            'app_content_indices'
          SET 
            size = coalesce(fileSize(location || name), 0)
        """)
      }),
    
    Config(
      state: .pending,
      version: .apr_11_2025_convert_urls_to_filepath,
      description: """
        Updates values in `IndexRecord.location` to fit expected database value for the equivalent FilePath
      """,
      migrateFn: { db in
        
          // Replaces encoded spaces, eg "/my%20folder/" -> "/my folder/
        try db.execute(sql: """
          update 
            app_content_indices
          SET
            location = replace(location, '%20', ' ')
        """)
        
          // Removes the leading "file://"
        try db.execute(sql: """
          UPDATE 
            app_content_indices
          SET 
            location = replace(location, 'file:///', '/')
        """)
        
          // Serialized FilePath paths omit the trailing forward-slash of folder paths
        try db.execute(sql: """
          UPDATE
            app_content_indices
          SET 
            location = regex_capture('^(.*)/$', location, 1)
          WHERE
            REGEXP('^.*/$', location)
        """)
      }),
    
    Config(
      state: .ready,
      version: .may_25_2025_create_savedqueries_table,
      description: """
        Adds table `SavedQueryRecord`
      """,
      checkFn: { db in
        try db.hasTable(SavedQueryRecord.self) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try SavedQueryRecord.createTable(db)
        
        try db.alter(table: TagRecord.databaseTableName) { table in
          table.rename(column: "value", to: "tagValue")
          table.rename(column: "label", to: "tagType")
          table.rename(column: "type", to: "entryType")
        }
      }),
    
    Config(
      state: .ready,
      version: .jun_1_2025_rename_tablerecord_columns,
      description: """
        Renamed columns in `TagRecord`:
        - `value` -> `tagValue`
        - `label` -> `tagType`
        - `type` -> `entryType`
      """,
      checkFn: { db in
        let tableCols = try db.columns(in: TagRecord.databaseTableName).map(\.name)
        let renamed = ["tagValue", "tagType", "entryType"]
        
        return tableCols.contains(all: renamed) ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.alter(table: TagRecord.databaseTableName) { table in
          table.rename(column: "value", to: "tagValue")
          table.rename(column: "label", to: "tagType")
          table.rename(column: "type", to: "entryType")
        }
      }),
    
    Config(
      state: .ready,
      version: .jun_4_2025_reomve_indexrecord_thumbnail,
      description: """
        Drops col `IndexRecord.thumbnail`
        """,
      checkFn: { db in
        try db.columns(in: IndexRecord.databaseTableName).map(\.name)
          .contains("thumbnail") ? .unmigrated : .migrated
      },
      migrateFn: { db in
        try db.alter(table: IndexRecord.databaseTableName) { table in
          table.drop(column: "thumbnail")
        }
      }),
    
    Config(
      state: .ready,
      version: .jun_9_2025_add_bookmarkrecord_contentId,
      description: """
        Drops col `BookmarkRecord.url`
        Drops col `BookmarkRecord.volume`
        Adds col `BookmarkRecord.contentId` (non-null, references IndexRecord.id)
        """,
      checkFn: { db in
        try db.columns(in: BookmarkRecord.databaseTableName).map(\.name).contains("contentId") ? .migrated : .unmigrated
      },
      migrateFn: { db in
        try db.drop(table: BookmarkRecord.self)
        
        try db.create(table: BookmarkRecord.databaseTableName) { table in
          table.id("id")
          table.column("created",  .date).notNull()
          table.column("contentId", .text).references(IndexRecord.databaseTableName, column: "id", onDelete: .cascade)
        }
      }),
    
    Config(
      state: .ready,
      version: .aug_2_2025_add_indexes_location_type_size_created_visibility,
      description: """
        Adds indexes to `app_content_indices`:
        - `location`
        - `type`
        - `size`
        - `created`
        - `visibility`
        """,
      migrateFn: { db in
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_app_content_indices_location ON app_content_indices(location);
            CREATE INDEX IF NOT EXISTS idx_app_content_indices_type ON app_content_indices(type);
            CREATE INDEX IF NOT EXISTS idx_app_content_indices_size ON app_content_indices(size);
            CREATE INDEX IF NOT EXISTS idx_app_content_indices_created ON app_content_indices(created);
            CREATE INDEX IF NOT EXISTS idx_app_content_indices_visibility ON app_content_indices(visibility);
        """)
        
      }
    )
  ]
}
