#if DEBUG
import Foundation
import GRDB
import System
import UniformTypeIdentifiers


struct UITestFixtureSeeder {
    static let savedQueryId = "uitest-saved-query-1"

    static func indexRecords(in tempDir: URL) -> [IndexRecord] {
        let dir = FilePath(tempDir.path)
        let now = Date.now

        return [
            makeIndexRecord(
                id: "content:uitest-alpha",
                name: "uitest-image-alpha.jpg",
                location: dir,
                type: UTType.jpeg,
                date: now),
            makeIndexRecord(
                id: "content:uitest-beta",
                name: "uitest-image-beta.jpg",
                location: dir,
                type: UTType.jpeg,
                date: now),
            makeIndexRecord(
                id: "content:uitest-gamma",
                name: "uitest-image-gamma.jpg",
                location: dir,
                type: UTType.jpeg,
                date: now),
            makeIndexRecord(
                id: "content:uitest-folder",
                name: tempDir.lastPathComponent,
                location: FilePath(tempDir.deletingLastPathComponent().path),
                type: UTType.folder,
                date: now),
        ]
    }

    static var tagRecords: [TagRecord] {
        [
            TagRecord(id: "tag:uitest-red",  tagValue: "red",  tagType: .tag),
            TagRecord(id: "tag:uitest-blue", tagValue: "blue", tagType: .tag),
        ]
    }

    static var indexTagRecords: [IndexTagRecord] {
        [
            IndexTagRecord(tagId: "tag:uitest-red",  contentId: ContentId(existing: "content:uitest-alpha")),
            IndexTagRecord(tagId: "tag:uitest-blue", contentId: ContentId(existing: "content:uitest-beta")),
        ]
    }

    static var savedQueryRecords: [SavedQueryRecord] {
        var filters = BrowseFilters()
        filters.tagsMatching = FilteringTagMultiParam(
            [FilteringTag.tag("red").asInclusive], operator: .or)
        return [
            SavedQueryRecord(id: savedQueryId, name: "UITest: Red Images", query: filters),
        ]
    }

    private static func makeIndexRecord(
        id: String,
        name: String,
        location: FilePath,
        type: UTType,
        date: Date,
        visibility: ContentItemVisibility = .normal
    ) -> IndexRecord {
        IndexRecord(
            id: ContentId(existing: id),
            timestamp: date,
            name: name,
            location: location,
            volume: VolumeInfo.defaultVolumeName,
            type: type,
            size: 1024,
            created: date,
            modified: date,
            comment: "",
            visibility: visibility)
    }
}


struct UITestLaunchHandler {

    /// `UserDefaults` key used to communicate a saved-query ID from `configure` to `AppViewModel`.
    static let uitestLoadSavedQueryKey = "UITestLoadSavedQueryId"

    static func configure(flags: RunFlags) {
        guard flags.uiTestMode, let folderPath = flags.launchFolderPath else { return }

        let tempDir = URL(fileURLWithPath: folderPath)
        let dbPath = FilePath(tempDir.appendingPathComponent(".hypertag-uitest.sqlite").path)

        IndexerContainer.shared.databasePath.register { dbPath }

        // Store the saved-query ID so AppViewModel can apply it after the indexer is ready.
        if let queryId = flags.loadSavedQuery {
            UserDefaults.standard.set(queryId, forKey: uitestLoadSavedQueryKey)
        } else {
            UserDefaults.standard.removeObject(forKey: uitestLoadSavedQueryKey)
        }
    }

    static func seed(service: GRDBIndexService, flags: RunFlags) throws {
        guard flags.uiTestMode, !flags.liveIndex,
              let folderPath = flags.launchFolderPath else { return }

        let tempDir = URL(fileURLWithPath: folderPath)
        let dbPath = FilePath(tempDir.appendingPathComponent(".hypertag-uitest.sqlite").path)

        let db = try DatabaseQueue(path: dbPath.string, configuration: GRDBIndexService.configure())

        try db.write { conn in
            for record in UITestFixtureSeeder.indexRecords(in: tempDir) {
                try record.insert(conn)
            }
            for record in UITestFixtureSeeder.tagRecords {
                try record.insert(conn)
            }
            for record in UITestFixtureSeeder.indexTagRecords {
                try record.insert(conn)
            }
            for record in UITestFixtureSeeder.savedQueryRecords {
                try record.insert(conn)
            }
        }
    }
}
#endif
