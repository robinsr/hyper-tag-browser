// created on 10/22/24 by robinsr

import Factory
import Foundation
import GRDB
import System

extension GRDBIndexService: ContentIndexer {

  private typealias TagCol = TagRecord.Columns
  private typealias TagItemCol = IndexTagRecord.Columns
  private typealias IndexCol = IndexRecord.Columns

  private var metrics: any MetricsRecorder { Container.shared.metricsRecorder() }


  func removeIndex(of pointers: [ContentPointer]) throws -> Int {
    try self.deleteIndexes(withIds: pointers.ids)
  }

  private func fetchIndexInfo(inTransaction db: Database, id: ContentId) throws -> IndexInfoRecord?
  {
    try IndexInfoRecord.fetch(withId: id).fetchOne(db)
  }


  private func getFilenameData(for url: URL) -> [FilteringTag] {
    let nameData = FilenameData(fileURL: url)

    // Extract tags from filename patterns
    let filenameTags = [
      nameData.mapTo(\.inBracesValues, type: .tag),
      nameData.mapTo(\.inBracketValues, type: .creator),
    ].flatMap(\.self)

    return filenameTags
  }

  private func assignIndexContentId(for path: FilePath) throws(IndexerServiceError) -> ContentId {
    let metadata = Container.shared.metadataService()

    var contentId: ContentId?

    do {
      contentId = try metadata.retrieveXID(for: path.fileURL)

      if contentId == nil {
        contentId = try metadata.assignNewXID(to: path.fileURL)
      }
    } catch {
      throw .OperationFailed(
        "Failed to retrieve or assign contentId for file \(path.string)", err: error)
    }

    guard contentId != nil else {
      throw .OperationFailed("Failed to retrieve or assign contentId for file \(path.string)")
    }

    return contentId!
  }


  /// Adds a new file to the index
  ///
  /// TODO: Will this update a file (name change, tag update?)
  func createIndex(inTransaction db: Database, path: FilePath) throws -> IndexInfoRecord {
    let contentId = try metrics.time("index.create.xid") { try assignIndexContentId(for: path) }

    // If IndexRecord already exists when createIndex is called, it is likely a file move or file rename.
    if var previous = try? IndexRecord.fetchOne(db, id: contentId) {
      previous.name = path.baseName
      previous.location = path.directory

      try previous.update(db)

      guard let indxinfo = try fetchIndexInfo(inTransaction: db, id: contentId) else {
        throw opFailed("Failed to load IndexInfoRecord for index \(contentId.value)")
      }

      return indxinfo
    }

    let indx = try IndexRecord(path: path, contentId: contentId)
    let indxExists = try indx.exists(db)

    var indxTags: [IndexTagRecord] = []

    if !indxExists {
      // Do not create TagRecords from filename patterns for existing indexes

      // TODO: Make this configurable in the UI
      let tagRecords = try metrics.time("index.create.filenameTags") {
        let filenameTags = getFilenameData(for: path.fileURL).asSet
        return try findOrCreateTags(inTransaction: db, for: filenameTags)
      }

      tagRecords
        .map { $0.newAssociation(toContentId: indx.id) }
        .forEach { indxTags.append($0) }
    }

    do {
      try metrics.time("index.create.insert") {
        try indx.insert(db, onConflict: .replace)
        try indxTags.forEach { try $0.insert(db) }
      }
    } catch {
      throw opFailed("Failed to insert new IndexRecord", err: error)
    }

    let fetched = try metrics.time("index.create.fetchInfo") {
      try fetchIndexInfo(inTransaction: db, id: indx.id)
    }

    guard let indxinfo = fetched else {
      throw opFailed("Failed to load IndexInfoRecord for conflicting ID '\(indx.id.value)'")
    }

    return indxinfo
  }


  func createIndex(for path: FilePath) throws -> IndexInfoRecord {
    try dbWriter.write { db in
      try createIndex(inTransaction: db, path: path)
    }
  }


  func diffDirectoryContents(
    of path: FilePath, mode: ListMode, parent: MetricSpan? = nil
  ) throws -> ContentPointerDiff {
    let fileservice = Container.shared.fileService()

    let listSpan = parent?.child("index.list")
    let dirContents: [ContentPointer] = fileservice.indexContents(
      at: path, mode: mode, types: .user)
    listSpan?.tag("files", dirContents.count)
    listSpan?.stop()

    let query = BrowseFilters(
      root: path,
      mode: mode,
      types: [.content, .folders],
      limit: 10000,
      visibility: .any
    )

    let lookupSpan = parent?.child("index.lookup")
    let indexed: [IndexRecord]

    do {
      indexed = try getIndexes(matching: query)
      lookupSpan?.tag("rows", indexed.count)
      lookupSpan?.stop()
    } catch {
      lookupSpan?.stop(outcome: .error)
      throw error
    }

    let indexedSet: Set<FilePath> = indexed.map(\.filepath).asSet
    let listingSet: Set<FilePath> = dirContents.map { $0.contentPath }.asSet

    let added = listingSet.subtracting(indexedSet).compactMap { dirContents[$0] }
    let removed = indexedSet.subtracting(listingSet).compactMap { indexed[$0] }.map(\.pointer)
    let unchanged = indexedSet.intersection(listingSet).compactMap { indexed[$0] }.map(\.pointer)

    return (removed, added, unchanged)
  }


  /**
   * Iterates through the directory contents of `url` and insert/updates `IndexRecord`s as needed.
   * Recorded as an `index.directory` span with one child span per pipeline step.
   *
   * TODO: Re-indexing a folder wipes out all the tags!
   */
  func indexDirectory(at path: FilePath) throws -> ContentIndexingResult {
    try metrics.span("index.directory").measure { span in
      try indexDirectory(at: path, span: span)
    }
  }

  private func indexDirectory(at path: FilePath, span: MetricSpan) throws -> ContentIndexingResult {
    let diff = try diffDirectoryContents(of: path, mode: .immediate(.uncached), parent: span)

    span.tag("folder_files", diff.added.count + diff.unchanged.count)
    span.tag("unchanged", diff.unchanged.count)

    let relocated: [ContentPointer] = try span.child("index.relocate").measure { step in
      let pointers = try dbWriter.write { db in
        try IndexRecord.all()
          .filter(ids: diff.added.ids)
          .filter(IndexRecord.Columns.location != path)
          .updateAndFetchAll(
            db,
            [
              IndexRecord.Columns.location.set(to: path)
            ]
          )
          .map(\.pointer)
      }

      step.tag("rows", pointers.count)
      logger.emit(.info, "Relocated \("record", qty: pointers.count)")
      return pointers
    }

    let deleted: [ContentPointer] = try span.child("index.delete").measure { step in
      let pointers = try dbWriter.write { db in
        try IndexRecord.all()
          .filter(ids: diff.removed.ids)
          .filter(IndexRecord.Columns.location == path)
          .deleteAndFetchAll(db)
          .map(\.pointer)
      }

      step.tag("rows", pointers.count)
      logger.emit(.info, "Deleted \("record", qty: pointers.count)")
      return pointers
    }

    let created: [ContentPointer] = try span.child("index.create").measure { step in
      let pointers = try dbWriter.write { db in
        let indexedIds = try IndexRecord.all()
          .select(IndexRecord.Columns.id)
          .filter(ids: diff.added.ids)
          .asRequest(of: ContentId.self)
          .fetchAll(db)

        let nonExistingIds = Set(diff.added.ids).subtracting(Set(indexedIds)).asArray

        return
          nonExistingIds
          .compactMap { id in
            diff.added.first(where: { $0.contentId == id })
          }
          .compactMap {
            (try? createIndex(inTransaction: db, path: $0.contentURL.filepath))?.pointer
          }
      }

      step.tag("rows", pointers.count)
      return pointers
    }

    span.tag("removed", deleted.count)
    span.tag("relocated", relocated.count)
    span.tag("created", created.count)
    span.tag("added", created.count + relocated.count)

    return ContentIndexingResult(
      removed: deleted,
      added: created + relocated,
      unchanged: diff.unchanged
    )
  }

  func search(_ query: SearchQuery) async throws -> [SpotlightResult] {
    let domainId = Container.shared.spotlightDomainIdentifier()

    let queryTerms = query.searchTerms

    var tagTokens =
      queryTerms
      .filter { $0.kind != .related }
      .map { FilteringTag.Filter(tag: $0.asFilter, effect: .inclusive) }

    let nameTokens =
      queryTerms
      .filter { $0.kind == .related }
      .map { $0.value }

    if tagTokens.isEmpty && nameTokens.isEmpty {
      // If no search terms are provided, use a random token to avoid all-matching query
      tagTokens.append(FilteringTag.tag(.randomIdentifier(40)).filterAs(.inclusive))
    }

    let params = BrowseFilters(
      root: query.searchRoot,
      mode: .recursive(.uncached),
      sortBy: query.searchSorting,
      tagsMatching: .init(tagTokens, operator: query.searchTermOperator),
      nameMatching: .init(nameTokens, operator: query.searchTermOperator),
      limit: query.paging.pageSize,
      offset: query.paging.offset,
      includeColumns: [.fileExists, .isFolder, .tagCount]
    )

    do {
      let contentItems = try await getContentItems(matching: params)

      return contentItems.map {
        SpotlightResult($0.asSearchableItem(in: domainId))
      }
    } catch {
      throw IndexerServiceError.searchFailed(error.legibleLocalizedDescription)
    }
  }
}
