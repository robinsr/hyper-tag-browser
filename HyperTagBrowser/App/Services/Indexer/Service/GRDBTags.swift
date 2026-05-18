// created on 10/22/24 by robinsr

import GRDB

extension GRDBIndexService: IndexTagAccess {

  private typealias IndxError = IndexerServiceError
  private typealias TagColumns = TagRecord.Columns
  private typealias IndexTagColumns = IndexTagRecord.Columns

  //
  // MARK: - Query Tags (get Bool)
  //

  func tagRecordExists(for filter: FilteringTag) async throws -> Bool {
    try await dbReader.read { db in
      try TagRecord.all().matching(filter: filter).fetchCount(db) > 0
    }
  }
  
  func queryTags(matching params: TagQueryParameters) async throws -> [CountedTagRecord] {
    try await dbReader.read { db in
      try CountedTagRecord.query(matching: params).fetchAll(db)
    }
  }

  //
  // MARK: - Query Tags (get TagRecord)
  //

  func getTagRecord(for filter: FilteringTag) async throws -> TagRecord? {
    try await dbReader.read { db in
      try TagRecord.all().matching(filter: filter).fetchOne(db)
    }
  }

  func getTagRecords(for filters: [FilteringTag]) async throws -> [TagRecord] {
    try await dbReader.read { db in
      try TagRecord.all().matching(filter: filters).fetchAll(db)
    }
  }
  
  func getTagRecords(for id: ContentId) async throws -> [TagRecord] {
    try await dbReader.read { db in
      let tagIds = IndexTagValueRecord.tagTable(for: id)
      
      return try TagRecord.all()
        .with(tagIds)
        .filter(tagIds.contains(TagColumns.id))
        .fetchAll(db)
    }
  }

  @available(*, deprecated, message: "Unused as of 2025-12-24")
  func getTagRecords(for pointer: ContentPointer) async throws -> [TagRecord] {
    return try await getTagRecords(for: pointer.contentId)
  }

  @available(*, deprecated, message: "Unused as of 2025-12-24")
  func getTagRecords(for index: IndexRecord) async throws -> [TagRecord] {
    return try await getTagRecords(for: index.contentId)
  }

  //
  // MARK: - Create Tags (new TagRecord)
  //

  func createTagRecord(for filter: FilteringTag) async throws -> TagRecord {
    if let existingTag = try await getTagRecord(for: filter) { return existingTag }

    return try await dbWriter.write { db in
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
  internal func removeTagIfUnused(_ filter: FilteringTag) async throws -> Bool {
    guard let tag = try await getTagRecord(for: filter) else {
      throw IndxError.DataIntegrityError("No tag found for value \(filter.rawValue)")
    }

    return try removeTagIfUnused(tag)
  }
}
