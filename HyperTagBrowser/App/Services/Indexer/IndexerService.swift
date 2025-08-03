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
  var error: IndexerServiceError? { get }

  var dbReader: GRDB.DatabaseReader { get }
  var dbWriter: GRDB.DatabaseWriter { get }

  func runMigrations() throws

  @discardableResult
  func runAsyncMigrations() async throws -> Future<String, Error>
}

/**
 * Defines the methods for indexing content
 */
protocol ContentIndexer {
  func indexDirectory(at: FilePath) throws -> ContentIndexingResult

  func createIndex(for: FilePath) throws -> IndexInfoRecord

  @discardableResult
  func removeIndex(of pointers: [ContentPointer]) throws -> Int
}

/**
 * Defines the methods for accessing the content indexes in the database.
 */
protocol IndexAccess {
  /// Gets the `IndexRecord` for the given ContentId if it exists
  func getIndex(withId: ContentId) throws -> IndexRecord?

  /// Gets all `IndexRecords` that match the supplied ``IndxRequestParams`` query parameters
  func getIndexes(matching: IndxRequestParams) throws -> [IndexRecord]
  
  /// Gets the `ContentId`s for all `IndexRecord`s matching the supplied ``IndxRequestParams`` query parameters
  func getIndexIds(matching: IndxRequestParams) throws -> [ContentId]

  /// Gets the `IndexInfoRecord` for the given ContentId if it exists
  func getIndexInfo(withId: ContentId) throws -> IndexInfoRecord?

  /// Gets the `IndexInfoRecord`s for the given set of ContentIds
  func getIndexInfo(withId: [ContentId]) throws -> [IndexInfoRecord]

  /// Gets all `IndexInfoRecord`s with a location matching the supplied URL
  func getIndexInfo(atPath: FilePath) throws -> [IndexInfoRecord]

  /// Gets all `IndexInfoRecord`s that match the supplied ``IndxRequestParams`` query parameters
  func getIndexInfo(matching params: IndxRequestParams) throws -> [IndexInfoRecord]

  /// Returns a list of all content-containing directories
  func getLocations() throws -> [FilePath]

  /// Initiates a change to the index database
  @discardableResult
  func updateIndexes(with: IndexRecord.Update) throws -> Int

  /// Initiates a change to the index database and returns the update `IndexRecord` records
  @discardableResult
  func updateAndFetchIndexes(with: IndexRecord.Update) throws -> [IndexRecord]

  /// Synchronizes filesystem state to the index database
  @discardableResult
  func syncIndexes(with changes: IndexRecord.Update) throws -> [IndexRecord]

  func deleteIndex(withId: ContentId) throws -> Bool

  func deleteIndexes(withIds: [ContentId]) throws -> Int
}


/**
 * Defines the methods for accessing tags in the database via the ``TagRecord`` type
 */
protocol IndexTagAccess {
  
  /**
   * Returns ``CountedTagRecord`` records (TagRecord with count of associations) matching
   * the supplied query parameters.
   */
  func queryTags(matching: TagQueryParameters) throws -> [CountedTagRecord]
  
  /**
   * Checks if a ``TagRecord`` exists for the supplied `FilteringTag` value.
   * - Returns: True if the TagRecord exists, false otherwise
   */
  func tagRecordExists(for: FilteringTag) throws -> Bool

  /**
   * Gets the ``TagRecord`` for the supplied `FilteringTag` value if it exists.
   * - Returns: The TagRecord matching the supplied FilteringTag value
   */
  func getTagRecord(for: FilteringTag) throws -> TagRecord?

  /**
   * Gets all tags that match the supplied FilteringTag values.
   * - Returns: The set of TagRecords matching the supplied FilteringTag values
   */
  func getTagRecords(for: [FilteringTag]) throws -> [TagRecord]

  /**
   * Gets all tags with associations to the content item with the given ``ContentId``.
   * - Returns: The set of TagRecords associated with the content item
   */
  func getTagRecords(for: ContentId) throws -> [TagRecord]
  
  func getTagRecords(for: ContentPointer) throws -> [TagRecord]

  func getTagRecords(for: IndexRecord) throws -> [TagRecord]

  func createTagRecord(for: FilteringTag) throws -> TagRecord
}



/**
 * Defines the methods for associating tags with content items, primarily via the ``IndexTagRecord`` type.
 */
protocol ContentTagAssociation {
  
    /// Adds the specified `FilteringTag` to the content items with the given IDs
  @discardableResult
  func associateTag(_: FilteringTag, toContentIds: [ContentId]) throws -> [IndexTagRecord]
  
    /// Adds the specified `FilteringTag`s to the content items matching the parameters
  @discardableResult
  func associateTag(_: FilteringTag, matching: IndxRequestParams) throws -> [IndexTagRecord]

    /// Adds the specified `FilteringTag`s to the content items with the given IDs
  @discardableResult
  func associateTags(_: [FilteringTag], toContentIds: [ContentId]) throws -> [IndexTagRecord]
  
    /// Adds the specified `FilteringTag`s to the content items matching the parameters
  @discardableResult
  func associateTags(_: [FilteringTag], matching: IndxRequestParams) throws -> [IndexTagRecord]
  
    /// Removes all tags from the content items and replaces them with the supplied set
  @discardableResult
  func replaceTags(forContent: [ContentId], withSet: [FilteringTag]) throws -> [IndexTagRecord]


  /**
   * Performs both an insert and a delete operation on the supplied content items
   *
   * - Parameters:
   *   - forContent: The content items to update
   *   - ensure: The tags to add to content items if not already present
   *   - remove: The tags to remove from content items if present
   * - Returns: The set of extant IndexInfoRecords for the content items
   */
  @discardableResult
  func modifyTags(forContent: [ContentId], ensure: [FilteringTag], remove: [FilteringTag]) throws
    -> TagAssociationChanges

  /**
   * Deletes the TagRecord matching the given value and all associated IndexTagRecords
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func removeTag(_: FilteringTag, scope: BatchScope) throws -> Int

  /**
   * Deletes the IndexTagRecords associated with the TagRecord matching the given value,
   * and the TagRecord if no associations remain
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func removeTag(_: FilteringTag, matching: IndxRequestParams) throws -> Int

  /**
   * Deletes only those IndexTagRecords associated with supplied contentId and matching
   * the given tag Value. Delete the TagRecord if no associations remain
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func removeTag(_: FilteringTag, fromContent: ContentId) throws -> Int

  /**
   * Deletes only those IndexTagRecords associated with supplied contentIds and matching
   * the given tag Value. Delete the TagRecord if no associations remain
   * - Returns: The number of IndexTagRecords deleted
   */
  @discardableResult
  func removeTag(_: FilteringTag, fromContent: [ContentId]) throws -> Int

  /**
   * Updates a TagRecord's value to a new value
   * - Returns: The updated TagRecord, and all associated IndexTagRecords
   */
  @discardableResult
  func renameTag(_: FilteringTag, to: FilteringTag) throws -> (TagRecord, [IndexTagRecord])

  /**
   * Update the value of a tag applied to content items matched by the supplied parameters
   * - Returns: The updated or created TagRecord and all associated IndexTagRecords
   */
  @discardableResult
  func renameTag(_: FilteringTag, to: FilteringTag, matching: IndxRequestParams) throws -> (
    TagRecord, [IndexTagRecord]
  )

  /**
   * Update the value of a tag applied to the supplied content items
   * - Returns: The updated or created TagRecord and all associated
   */
  @discardableResult
  func renameTag(_: FilteringTag, to: FilteringTag, for: [ContentId]) throws -> (
    TagRecord, [IndexTagRecord]
  )

  /**
   * Consolidates the value of one tag into another. All IndexTagRecords associated
   * with the source tag are updated to the target tag value
   * - Returns: The updated IndexTagRecords
   */
  @discardableResult
  func consolidateTag(_: FilteringTag, into: FilteringTag) throws -> [IndexTagRecord]
}

/**
 * Defines the methods for accessing bookmarks in the database, primarily via the ``BookmarkRecord`` type.
 */
protocol BookmarkAccess {
    /// Checks if a BookmarkRecord exists for the specified contentId
  func bookmarkExists(to: ContentId) throws -> Bool
  
    /// Retreives the BookmarkRecord for the specified FilePath if it exists.
  func findBookmark(withPath: FilePath) throws -> BookmarkInfoRecord?

    /// Retrieves the BookmarkRecord for the specified contentId if it exists.
  func getBookmark(for: ContentId) throws -> BookmarkInfoRecord?

    /// Creates a BookmarkRecord for the specified contentId.
  func createBookmark(to: ContentId) throws -> BookmarkInfoRecord

    /// Deletes the BookmarkRecord with the specified contentId.
  func deleteBookmark(withId: BookmarkRecord.ID) throws -> BookmarkInfoRecord?

    /// Deletes all BookmarkRecords for the specified contentId, returning the deleted records.
  func deleteBookmarks(to: ContentId) throws -> [BookmarkRecord]
}

/**
 * Defines the methods for accessing saved queries in the database, primarily via the ``SavedQueryRecord`` type.
 */
protocol SavedQueryAccess {
  func getSavedQuery(withId: SavedQueryRecord.ID) throws -> SavedQueryRecord?

  func listSavedQueries() throws -> [SavedQueryRecord]

  func createSavedQuery(named: String, using: BrowseFilters) throws -> SavedQueryRecord

  func updateSavedQuery(withId: SavedQueryRecord.ID, using: BrowseFilters) throws
    -> SavedQueryRecord

  func renameSavedQuery(withId: SavedQueryRecord.ID, to: String) throws -> SavedQueryRecord

  func deleteSavedQuery(withId: SavedQueryRecord.ID) throws -> Bool
}

/**
 * Defines the methods for associating content items with queues, primarily via the ``QueueRecord`` type.
 */
protocol ContentQueueAssociation {
  func createQueue(named: String) throws -> QueueRecord

  func insertIntoQueue(queueId: String, content: ContentId) throws
  func insertIntoQueue(queueId: String, content: [ContentId]) throws
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
struct ContentIndexingResult {
  var removed: [ContentPointer] = []
  var added: [ContentPointer] = []
  var unchanged: [ContentPointer] = []
  var duplicates: [ContentPointer] = []
}

/**
 * A typealias representing a set of changes made to tag associations for content items,
 * enumerating the tags that were added and removed.
 */
typealias TagAssociationChanges = (added: [IndexTagRecord], removed: [IndexTagRecord])

typealias AndOrOperator = SQLExpression.AssociativeBinaryOperator
