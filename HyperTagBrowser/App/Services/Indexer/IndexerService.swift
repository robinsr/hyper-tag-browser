// created on 10/14/24 by robinsr

import Combine
import Foundation
import GRDB
import System
import UniformTypeIdentifiers

protocol IndexerService: IndexerConnection & ContentIndexer & IndexAccess & ContentTagAssociation
    & ContentQueueAssociation & BookmarkAccess
{}

/**
 * Defines the connection to the index database
 */
protocol IndexerConnection {
  var dbName: String { get }
  var dbReader: GRDB.DatabaseReader { get }
  var dbWriter: GRDB.DatabaseWriter { get }
  func runMigrations() throws
}

/**
 * Defines the methods for indexing content
 */
protocol ContentIndexer {
  @discardableResult
  func indexDirectory(at: FilePath) async throws -> ContentIndexingResult

  @discardableResult
  func createIndex(for: FilePath) async throws -> IndexInfoRecord

  @discardableResult
  func removeIndex(of pointers: [ContentPointer]) async throws -> Int
  
  func search(_ query: SearchQuery) async throws -> [SpotlightResult]
}

/**
 * Defines the methods for accessing the content indexes in the database.
 */
protocol IndexAccess {
  func indexExists(withPath: FilePath) async throws -> Bool
  
  /// Gets the `IndexRecord` for the given ContentId if it exists
  @discardableResult
  func getIndex(withId: ContentId) async throws -> IndexRecord?
  
  @discardableResult
  func getIndex(withPath: FilePath) async throws -> IndexRecord?

  /// Gets all `IndexRecords` that match the supplied ``IndxRequestParams`` query parameters
  @discardableResult
  func getIndexes(matching: IndxRequestParams) async throws -> [IndexRecord]
  
  /// Gets the `ContentId`s for all `IndexRecord`s matching the supplied ``IndxRequestParams`` query parameters
  @discardableResult
  func getIndexIds(matching: IndxRequestParams) async throws -> [ContentId]

  /// Gets the `IndexInfoRecord` for the given ContentId if it exists
  @discardableResult
  func getContentItem(withId: ContentId) async throws -> IndexInfoRecord?
  
  @discardableResult
  func getContentItem(atPath: FilePath) async throws -> IndexInfoRecord?

  /// Gets the `IndexInfoRecord`s for the given set of ContentIds
  @discardableResult
  func getContentItems(withId: [ContentId]) async throws -> [IndexInfoRecord]

  /// Gets all `IndexInfoRecord`s with a location matching the supplied URL
  @discardableResult
  func getContentItems(inFolder: FilePath) async throws -> [IndexInfoRecord]

  /// Gets all `IndexInfoRecord`s that match the supplied ``IndxRequestParams`` query parameters
  @discardableResult
  func getContentItems(matching params: IndxRequestParams) async throws -> [IndexInfoRecord]

  /// Returns a list of all content-containing directories
  @discardableResult
  func getLocations() async throws -> [FilePath]

  /// Initiates a change to the index database
  @discardableResult
  func updateIndexes(with: IndexRecord.Update) async throws -> Int

  /// Initiates a change to the index database and returns the update `IndexRecord` records
  @discardableResult
  func updateAndFetchIndexes(with: IndexRecord.Update) async throws -> [IndexRecord]

  /// Synchronizes filesystem state to the index database
  @discardableResult
  func syncIndexes(with changes: IndexRecord.Update) async throws -> [IndexRecord]

  @discardableResult
  func deleteIndex(withId: ContentId) async throws -> Bool

  @discardableResult
  func deleteIndexes(withIds: [ContentId]) async throws -> Int
}


/**
 * Defines the methods for accessing tags in the database via the ``TagRecord`` type
 */
protocol IndexTagAccess {
  
  /**
   * Returns a set of ``CountedTagRecord`` records (`TagRecord` with count of associations) matching
   * the supplied query parameters.
   */
  func queryTags(matching: TagQueryParameters) async throws -> [CountedTagRecord]
  
  /**
   * Returns true if a `TagRecord` exists for the supplied `FilteringTag` value.
   */
  func tagRecordExists(for: FilteringTag) async throws -> Bool

  /**
   * Returns a `TagRecord` record that corresponds to the provided `FilteringTag`
   */
  func getTagRecord(for: FilteringTag) async throws -> TagRecord?

  /**
   * Returns a set of `TagRecord` records that correspond to the provided set of `FilteringTag`s
   */
  func getTagRecords(for: [FilteringTag]) async throws -> [TagRecord]

  /**
   * Returns a set of `TagRecord` records associated to the `IndexRecord` identified by the provided `ContentId`
   */
  func getTagRecords(for: ContentId) async throws -> [TagRecord]
  
  /**
   * Returns a set of `TagRecord` records associated to the `IndexRecord` identified by the provided `ContentPointer`
   */
  func getTagRecords(for: ContentPointer) async throws -> [TagRecord]

  /**
   * Returns a set of `TagRecord` records associated to the provided `IndexRecord`
   */
  func getTagRecords(for: IndexRecord) async throws -> [TagRecord]

  /**
   * Creates a new `TagRecord`, or returns an existing `TagRecord`, for the provided `FilteringTag`
   */
  @discardableResult
  func createTagRecord(for: FilteringTag) async throws -> TagRecord
}



/**
 * Defines the methods for associating tags with content items, primarily via the ``IndexTagRecord`` type.
 */
protocol ContentTagAssociation {
  
  /**
   * Adds the specified tag to the content items with the given IDs
   *
   * - Returns: The ``IndexInfoRecords`` created (or fetched) for the matching content items
   */
  @discardableResult
  func tag(_: FilteringTag, on: [ContentId]) async throws -> [IndexTagRecord]
  
  /**
   * Adds the specified tag to the content items matching the parameters
   *
   * - Returns: The ``IndexInfoRecords`` created (or fetched) for the matching content items
   */
  @discardableResult
  func tag(_: FilteringTag, matching: IndxRequestParams) async throws -> [IndexTagRecord]

  /**
   * Adds the specified tags to the content items with the given IDs
   *
   * - Returns: The ``IndexInfoRecords`` created (or fetched) for the matching content items
   */
  @discardableResult
  func tag(_: [FilteringTag], on: [ContentId]) async throws -> [IndexTagRecord]
  
  /**
   * Adds the specified tags to the content items matching the parameters
   *
   * - Returns: The ``IndexInfoRecords`` created (or fetched) for the matching content items
   */
  @discardableResult
  func tag(_: [FilteringTag], matching: IndxRequestParams) async throws -> [IndexTagRecord]
  
  /**
   * Sets the tag associations for each content item indiciated
   *
   * - Returns: The set of extant ``IndexInfoRecords`` for the content items
   */
  @discardableResult
  func setTags(_: [FilteringTag], on: [ContentId]) async throws -> [IndexTagRecord]


  /**
   * Performs both an insert and a delete operation on the supplied content items
   *
   * - Parameters:
   *   - adding: The tags to add to content items if not already present
   *   - removing: The tags to remove from content items if present
   *   - on: The content items to update
   *
   * - Returns: The set of extant ``IndexInfoRecords`` for the content items
   */
  @discardableResult
  func setTags(adding: [FilteringTag], removing: [FilteringTag], on: [ContentId]) async throws -> IndexTagRecord.ChangeSet

  /**
   * Deletes the TagRecord matching the given value and all associated IndexTagRecords
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func untag(_: FilteringTag, scope: BatchScope) async throws -> Int

  /**
   * Deletes the IndexTagRecords associated with the TagRecord matching the given value,
   * and the TagRecord if no associations remain
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func untag(_: FilteringTag, matching: IndxRequestParams) async throws -> Int

  /**
   * Deletes only those IndexTagRecords associated with supplied contentId and matching
   * the given tag Value. Delete the TagRecord if no associations remain
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func untag(_: FilteringTag, from: ContentId) async throws -> Int

  /**
   * Deletes only those IndexTagRecords associated with supplied contentIds and matching
   * the given tag Value. Delete the TagRecord if no associations remain
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func untag(_: FilteringTag, from: [ContentId]) async throws -> Int

  /**
   * Updates a TagRecord's value to a new value
   * - Returns: The updated TagRecord, and all associated IndexTagRecords
   */
  @discardableResult
  func renameTag(_: FilteringTag, to: FilteringTag) async throws -> (TagRecord, [IndexTagRecord])

  /**
   * Update the value of a tag applied to content items matched by the supplied parameters
   * - Returns: The updated or created TagRecord and all associated IndexTagRecords
   */
  @discardableResult
  func renameTag(
    _: FilteringTag,
    to: FilteringTag,
    matching: IndxRequestParams
  ) async throws -> (TagRecord, [IndexTagRecord])

  /**
   * Update the value of a tag applied to the supplied content items
   * - Returns: The updated or created TagRecord and all associated
   */
  @discardableResult
  func renameTag(
    _: FilteringTag,
    to: FilteringTag,
    for: [ContentId]) async throws -> (TagRecord, [IndexTagRecord])

  /**
   * Consolidates the value of one tag into another. All IndexTagRecords associated
   * with the source tag are updated to the target tag value
   * - Returns: The updated IndexTagRecords
   */
  @discardableResult
  func consolidateTag(_ source: FilteringTag, into target: FilteringTag) async throws -> [IndexTagRecord]
}

/**
 * Defines the methods for accessing bookmarks in the database, primarily via the ``BookmarkRecord`` type.
 */
protocol BookmarkAccess {
    /// Checks if a BookmarkRecord exists for the specified contentId
  func bookmarkExists(to: ContentId) async throws -> Bool
  
    /// Retreives the BookmarkRecord for the specified FilePath if it exists.
  func findBookmark(withPath: FilePath) async throws -> BookmarkInfoRecord?

    /// Retrieves the BookmarkRecord for the specified contentId if it exists.
  func getBookmark(for: ContentId) async throws -> BookmarkInfoRecord?

    /// Creates a BookmarkRecord for the specified contentId.
  func createBookmark(to: ContentId) async throws -> BookmarkInfoRecord

    /// Deletes the BookmarkRecord with the specified contentId.
  func deleteBookmark(withId: BookmarkRecord.ID) async throws -> BookmarkInfoRecord?

    /// Deletes all BookmarkRecords for the specified contentId, returning the deleted records.
  func deleteBookmarks(to: ContentId) async throws -> [BookmarkRecord]
}

/**
 * Defines the methods for accessing saved queries in the database, primarily via the ``SavedQueryRecord`` type.
 */
protocol SavedQueryAccess {
  func getSavedQuery(withId: SavedQueryRecord.ID) async throws -> SavedQueryRecord?

  func listSavedQueries() async throws -> [SavedQueryRecord]

  func createSavedQuery(named: String, using: BrowseFilters) async throws -> SavedQueryRecord

  func updateSavedQuery(withId: SavedQueryRecord.ID, using: BrowseFilters) async throws -> SavedQueryRecord

  func renameSavedQuery(withId: SavedQueryRecord.ID, to: String) async throws -> SavedQueryRecord

  func deleteSavedQuery(withId: SavedQueryRecord.ID) async throws -> Bool
}

/**
 * Defines the methods for associating content items with queues, primarily via the ``QueueRecord`` type.
 */
protocol ContentQueueAssociation {
  func createQueue(named: String) async throws -> QueueRecord
  func insertIntoQueue(queueId: String, content: ContentId) async throws
  func insertIntoQueue(queueId: String, content: [ContentId]) async throws
}

/**
 * A tuple representing the a changeset of content pointers, typically used to represent
 * the results of a content indexing operation.
 */
typealias ContentPointerDiff = (
  removed: [ContentPointer], added: [ContentPointer], unchanged: [ContentPointer]
)

/**
 * Represents the result of a content indexing operation, including lists of content pointers
 * that were removed, added, unchanged, or duplicates.
 */
struct ContentIndexingResult: Sendable, CustomStringConvertible {
  let removed: [ContentPointer]
  let added: [ContentPointer]
  let unchanged: [ContentPointer]
  let duplicates: [ContentPointer]
  
  init(
    removed: [ContentPointer] = [],
    added: [ContentPointer] = [],
    unchanged: [ContentPointer] = [],
    duplicates: [ContentPointer] = []
  ) {
    self.removed = removed
    self.added = added
    self.unchanged = unchanged
    self.duplicates = duplicates
  }
  
  var description: String {
    "\(added.count) new, \(removed.count) removed, \(unchanged.count) unchanged"
  }
  
  var hasDuplicates: Bool {
    duplicates.count > 0
  }
}

/**
 * A typealias representing a set of changes made to tag associations for content items,
 * enumerating the tags that were added and removed.
 */
//typealias TagAssociationChanges = (added: [IndexTagRecord], removed: [IndexTagRecord])

typealias AndOrOperator = SQLExpression.AssociativeBinaryOperator
