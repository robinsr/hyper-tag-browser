// created on 10/22/24 by robinsr

import GRDB

extension GRDBIndexService: IndexTagAccess {

  private typealias IndxError = IndexerServiceError
  private typealias TagColumns = TagRecord.Columns
  private typealias IndexTagColumns = IndexTagRecord.Columns

  //
  // MARK: - Query Tags (get Bool)
  //

  func tagRecordExists(for filter: FilteringTag) throws -> Bool {
    try dbReader.read { db in
      try TagRecord.all().matching(filter: filter).fetchCount(db) > 0
    }
  }
  
  func queryTags(matching params: TagQueryParameters) throws -> [CountedTagRecord] {
    try dbReader.read { db in
      try CountedTagRecord.query(matching: params).fetchAll(db)
    }
  }

  //
  // MARK: - Query Tags (get TagRecord)
  //

  func getTagRecord(for filter: FilteringTag) throws -> TagRecord? {
    try dbReader.read { db in
      try TagRecord.all().matching(filter: filter).fetchOne(db)
    }
  }

  func getTagRecords(for filters: [FilteringTag]) throws -> [TagRecord] {
    try dbReader.read { db in
      try TagRecord.all().matching(filter: filters).fetchAll(db)
    }
  }

  func getTagRecords(for id: ContentId) throws -> [TagRecord] {
    let tagIds = IndexTagValueRecord.tagTable(for: id)

    return try dbReader.read { db in
      try TagRecord.all()
        .with(tagIds)
        .filter(tagIds.contains(TagColumns.id))
        .fetchAll(db)
    }
  }

  func getTagRecords(for pointer: ContentPointer) throws -> [TagRecord] {
    return try getTagRecords(for: pointer.contentId)
  }

  func getTagRecords(for index: IndexRecord) throws -> [TagRecord] {
    return try getTagRecords(for: index.contentId)
  }

  //
  // MARK: - Create Tags (new TagRecord)
  //

  func createTagRecord(for filter: FilteringTag) throws -> TagRecord {
    if let existingTag = try getTagRecord(for: filter) { return existingTag }

    return try dbWriter.write { db in
      try TagRecord(filter).inserted(db)
    }
  }

  /**
   * Returns a set of TagRecords for a set of strings, creating new tag records as
   * needed if they don't already exist.
   */
  func findOrCreateTags(
    inTransaction db: Database,
    for filters: Set<FilteringTag>
  ) throws -> [TagRecord] {
    var extantRecords = try TagRecord.all().matching(filter: filters.asArray).fetchAll(db)

    try filters
      .subtracting(extantRecords.filteringTags)
      .forEach { extantRecords.append(try TagRecord($0).inserted(db)) }

    if extantRecords.count < filters.count {
      let failedTags = filters.subtracting(extantRecords.filteringTags)

      logger.emit(
        .warning,
        """
          Failed to create all desired tags. 
          Missing tags: \(failedTags). 
          Proceeding with \("created tags", qty: extantRecords.count)
        """)
    }

    return extantRecords
  }

  func findOrCreateTagRecords(for filters: [FilteringTag]) throws -> [TagRecord] {
    return try dbWriter.write { db in
      try findOrCreateTags(inTransaction: db, for: filters.asSet)
    }
  }

  //
  // MARK: - Delete Tags (delete TagRecord)
  //

  @discardableResult
  internal func removeTagIfUnused(_ tag: TagRecord) throws -> Bool {
    let tagValue = tag.asFilter.rawValue

    guard let associations = try getContentAssociations(tagId: tag.id).nilIfEmpty else {
      logger.emit(.debug, "No tag associations found for tag \(tagValue). Deleting tag")

      return try dbWriter.write { db in
        try tag.delete(db)
      }
    }

    logger.emit(
      .debug,
      "\("Tag associations", qty: associations.count) found for tag \(tagValue). Retaining tag")

    return false
  }

  @discardableResult
  internal func removeTagIfUnused(_ filter: FilteringTag) throws -> Bool {
    guard let tag = try getTagRecord(for: filter) else {
      throw IndxError.DataIntegrityError("No tag found for value \(filter.rawValue)")
    }

    return try removeTagIfUnused(tag)
  }

  //
  // MARK: - Delete Tags (delete IndexTagRecord)
  //

  func removeTag(_ filter: FilteringTag, scope: BatchScope) throws -> Int {
    guard let tag = try getTagRecord(for: filter) else {
      throw IndxError.DataIntegrityError("No tag found for value '\(filter)'")
    }

    let request =
      switch scope {
        case .all:
          IndexTagRecord.all().matching(filter: filter)
        default:
          throw IndxError.InvalidParameter("Scope '\(scope)' not yet supported for tag deletion")
      }

    let deleteCount = try dbWriter.write { db in
      return try request.deleteAll(db)
    }

    let tagWasDeleted = try removeTagIfUnused(tag)

    logger
      .emit(
        .info,
        "Deleted \("tag associations", qty: deleteCount) for tag \(filter). Deleted tag: \(tagWasDeleted)"
      )

    return deleteCount
  }

  func removeTag(_ filter: FilteringTag, fromContent ids: [ContentId]) throws -> Int {
    guard let tag = try getTagRecord(for: filter) else {
      throw IndxError.DataIntegrityError("No tag found for value \(filter.rawValue)")
    }

    let deleteCount = try dbWriter.write { db in
      try IndexTagRecord.all()
        .matching(contentId: ids)
        .matching(filter: filter)
        .deleteAll(db)
    }

    try removeTagIfUnused(tag)

    return deleteCount
  }

  func removeTag(_ filter: FilteringTag, fromContent id: ContentId) throws -> Int {
    try removeTag(filter, fromContent: [id])
  }

  func removeTag(_ filter: FilteringTag, matching params: IndxRequestParams) throws -> Int {
    let contentIds = try getIndexes(matching: params).map(\.contentId)
    return try removeTag(filter, fromContent: contentIds)
  }
}
