// created on 6/2/25 by robinsr

import GRDB

extension GRDBIndexService: ContentTagAssociation {
  private typealias IndxError = IndexerServiceError

  private typealias TagColumns = TagRecord.Columns
  private typealias IndexTagColumns = IndexTagRecord.Columns

  // MARK: - Query Associations (get TagIndexRecord)

  func getContentAssociations(tagId ids: [TagRecord.ID]) throws -> [IndexTagRecord] {
    return try dbReader.read { db in
      try IndexTagRecord.all()
        .filter(ids.contains(IndexTagColumns.tagId))
        .fetchAll(db)
    }
  }

  // MARK: - Query Associations (get ContentId)

  func getContentAssociations(tagId: TagRecord.ID) throws -> [IndexTagRecord] {
    return try dbReader.read { db in
      try IndexTagRecord.all()
        .matching(tagId: tagId)
        .fetchAll(db)
    }
  }

  func getContentIdAssociations(forTag id: TagRecord.ID) throws -> [ContentId] {
    return try getContentAssociations(tagId: id).map(\.contentId)
  }

  // MARK: - Associate Tags (new TagIndexRecord)

  //  @discardableResult
  //  internal func associateTagWithContent(tag: TagRecord, contentId id: ContentId) throws -> IndexTagRecord {
  //    try dbWriter.write { db in
  //      try tag.newAssociation(toContentId: id).inserted(db)
  //    }
  //  }

  //  @discardableResult
  //  internal func associateTagWithContent(tag: TagRecord, contentIds: [ContentId]) throws -> [IndexTagRecord] {
  //    try dbWriter.write { db in
  //      return try contentIds.map { id in
  //        try tag.newAssociation(toContentId: id).inserted(db)
  //      }
  //    }
  //  }

  // MARK: - Add Tags (new TagRecord)

  func associateTag(_ filter: FilteringTag, toContentIds ids: [ContentId]) throws -> [IndexTagRecord] {
    guard let tag = try findOrCreateTagRecords(for: [filter]).first else {
      throw IndxError.OperationFailed("Failed to create tag for value \(filter)")
    }

    return try dbWriter.write { db in
      try ids.map { id in
        try tag.newAssociation(toContentId: id).inserted(db)
      }
    }
  }

  func associateTags(_ tags: [FilteringTag], toContentIds ids: [ContentId]) throws -> [IndexTagRecord] {
    let tagRecords = try findOrCreateTagRecords(for: tags)

    return try dbWriter.write { db in
      try tagRecords
        .flatMap { tag in
          ids.map { id in
            tag.newAssociation(toContentId: id)
          }
        }
        .map { association in
          try association.inserted(db, onConflict: .ignore)
        }
    }
  }
  
  func associateTag(_ filter: FilteringTag, matching params: IndxRequestParams) throws -> [IndexTagRecord] {
    return try associateTag(filter, toContentIds: try getIndexIds(matching: params))
  }
  
  func associateTags(_ filters: [FilteringTag], matching params: IndxRequestParams) throws -> [IndexTagRecord] {
    return try associateTags(filters, toContentIds: try getIndexIds(matching: params))
  }

  // MARK: - Modify Tags (new TagRecord, new TagIndexRecord, delete TagIndexRecord, delete TagRecord)

  func patchTag(withId id: TagRecord.ID, using patch: TagRecord.Update) throws -> TagRecord {
    try dbWriter.write { db in
      let tagrecords = try TagRecord.all()
        .filter(key: id)
        .updateAndFetchAll(db, patch.assignment)

      guard let tag = tagrecords.first else {
        throw IndxError.OperationFailed(patch.failedMessage)
      }

      logger.emit(.info, patch.successMessage)

      return tag
    }
  }

  private func modifyTags(contentId: ContentId, addedTags: [TagRecord], removingTags: [TagRecord])
    throws -> TagAssociationChanges
  {

    var extantAssociations: [IndexTagRecord] = []
    var deletedAssociations: [IndexTagRecord] = []

    try dbWriter.write { db in
      let associations = try IndexTagRecord.forContent(contentId).fetchAll(db)
      let missingTagIds = addedTags.tagIds.subtracting(associations.tagIds)
      let droppedTagIds = removingTags.tagIds.intersection(associations.tagIds)

      try missingTagIds
        .map { try IndexTagRecord(tagId: $0, contentId: contentId).inserted(db) }
        .forEach { extantAssociations.append($0) }

      deletedAssociations.append(
        contentsOf: try IndexTagRecord.all()
          .matching(contentId: contentId)
          .matching(tagId: droppedTagIds.asArray)
          .deleteAndFetchAll(db)
      )

      logger.debug(
        """
          \(associations.count) "existing tag associations found for content \(contentId.shortId.quoted)
          - Adding tags: \(missingTagIds)
          - Removing tags: \(droppedTagIds)
        """)
    }

    return (extantAssociations, deletedAssociations)
  }

  @discardableResult
  func modifyTags(
    forContent contentIds: [ContentId],
    ensure keepFilters: [FilteringTag],
    remove deleteFilters: [FilteringTag]
  ) throws -> TagAssociationChanges {

    let addedTags = try findOrCreateTagRecords(for: keepFilters)
    let removingTags = try getTagRecords(for: deleteFilters)

    var extantAssociations: [IndexTagRecord] = []
    var deletedAssociations: [IndexTagRecord] = []

    for contentId in contentIds {
      let (extant, deleted) = try modifyTags(
        contentId: contentId, addedTags: addedTags, removingTags: removingTags)

      extantAssociations.append(contentsOf: extant)
      deletedAssociations.append(contentsOf: deleted)
    }

    let deleteCount =
      try removingTags
      .map { tag in try removeTagIfUnused(tag) }
      .filter { $0 == true }
      .count

    logger.debug(
      """
        Sumamry of tag association changes
        - ContentIds: \(contentIds.values):
        - Adding/Keeping tags: \(addedTags.map(\.asFilter.rawValue))
        - Removing tags: \(removingTags.map(\.asFilter.rawValue))


        - \(deleteCount)/\(removingTags.count) tag record deletions
        - \(extantAssociations.count) tag associations added
        - \(deletedAssociations.count) tag associations removed
      """)

    return (extantAssociations, deletedAssociations)
  }

  // MARK: - Replace Tags (new TagRecord, delete/new TagIndexRecord)

  /**
   Removes all existing tag associations on contentIds and replaces them with new tags.
   */
  func replaceTags(forContent ids: [ContentId], withSet newTags: [FilteringTag]) throws
    -> [IndexTagRecord]
  {

    /// Get the current state before making any changes
    let indexRecords = try getIndexInfo(withId: ids)
    let oldAssociations = indexRecords.flatMap(\.tagValues)

    /// Ensure there is a TagRecord for each new tag, either creating a new one or fetching an existing
    let tagRecords = try findOrCreateTagRecords(for: newTags)

    /// Create new associations for each content and each new tag
    let newAssociations = try dbWriter.write { db in
      try tagRecords
        .flatMap { tag in ids.map { id in tag.newAssociation(toContentId: id) } }
        .map { association in
          try association.inserted(db, onConflict: .replace)
        }
    }

    /// Determine the set of old associations that are no longer needed
    let oldAssociationIds = Set(oldAssociations.map(\.id)).subtracting(newAssociations.map(\.id))

    /// Remove old associations that are no longer needed
    let deleteCount = try dbWriter.write { db in
      try IndexTagRecord.all()
        .filter(oldAssociationIds.contains(IndexTagColumns.id))
        .deleteAll(db)
    }

    logger.emit(
      .info,
      """
      Replaced tags for \(ids.count) content items: 
      \(deleteCount)/\(oldAssociationIds.count) tag deletions
      \(newAssociations.count) tag associations 
      """)

    return newAssociations
  }

  func replaceTags(forContent id: ContentId, withSet values: [FilteringTag]) throws
    -> [IndexTagRecord]
  {
    try self.replaceTags(forContent: [id], withSet: values)
  }

  // MARK: - Rename Tags (delete TagRecord, new TagRecord/TagIndexRecord)

  func renameTag(_ prevFilter: FilteringTag, to newFilter: FilteringTag) throws -> (
    TagRecord, [IndexTagRecord]
  ) {
    guard let prevTagId = try getTagRecord(for: prevFilter)?.id else {
      throw IndxError.DataIntegrityError("No tag found for value \(prevFilter.rawValue)")
    }

    if try tagRecordExists(for: newFilter) {
      logger.emit(
        .info, "Tag with value '\(newFilter.rawValue)' already exists. Consolidating tags instead")

      let updated = try consolidateTag(prevFilter, into: newFilter)

      logger.emit(.info, "Consolidated tags: \(updated.count) tag association updates")

      guard let tag = try getTagRecord(for: newFilter) else {
        throw IndxError.OperationFailed("Expected tag \(prevFilter) to exist after consolidation")
      }

      return (tag, updated)
    }

    let targetTag = try self.patchTag(
      withId: prevTagId,
      using: .fromFilter(newFilter)
    )

    let tagAssociations = try getContentAssociations(tagId: prevTagId)

    logger.emit(
      .info,
      "Renamed tag \(prevFilter) to \(newFilter), \(tagAssociations.count) tag association updates")

    return (targetTag, tagAssociations)
  }

  func renameTag(_ prev: FilteringTag, to updated: FilteringTag, for ids: [ContentId]) throws -> (
    TagRecord, [IndexTagRecord]
  ) {

    guard let prevTag = try getTagRecord(for: prev) else {
      throw IndxError.DataIntegrityError("No tag found for value \(prev)")
    }

    let currentTagAssociations = try dbReader.read { db in
      try IndexTagRecord.all()
        .matching(tagId: prevTag.id)
        .fetchAll(db)
    }

    if currentTagAssociations.count == 0 {
      throw IndxError.DataIntegrityError("No tag associations found for tag \(prev)")
    }

    let newTag = try createTagRecord(for: updated)

    let touched = try dbWriter.write { db in
      try IndexTagRecord.all()
        .matching(tagId: prevTag.id)
        .matching(contentId: ids)
        .updateAndFetchAll(
          db,
          [
            IndexTagColumns.tagId.set(to: newTag.id)
          ])
    }

    let didDelete = try removeTagIfUnused(prevTag)

    logger
      .emit(
        .info,
        "Renamed tag \(prev) to \(updated), \("tag association updates", qty: touched.count), deleted tag: \(didDelete)"
      )

    return (newTag, touched)
  }

  func renameTag(_ prev: FilteringTag, to updated: FilteringTag, matching params: IndxRequestParams)
    throws -> (TagRecord, [IndexTagRecord])
  {
    return try renameTag(prev, to: updated, for: try getIndexes(matching: params).map(\.contentId))
  }

  // MARK: - Consolidate Tags (new TagIndexRecord, delete TagRecord)

  func consolidateTag(fromTag: TagRecord, intoTag: TagRecord) throws -> [IndexTagRecord] {
    let updated = try dbWriter.write { db in
      try IndexTagRecord.all()
        .matching(tagId: fromTag.id)
        .updateAndFetchAll(
          db, onConflict: .replace,
          [
            IndexTagColumns.tagId.set(to: intoTag.id)
          ])
    }

    let didDelete = try removeTagIfUnused(fromTag)

    logger.emit(
      .info,
      "Consolidated tag \(fromTag.tagValue) into \(intoTag.tagValue): \(updated.count) tag association updates, \(didDelete) tag deletion"
    )

    return updated
  }

  func consolidateTag(_ from: FilteringTag, into: FilteringTag) throws -> [IndexTagRecord] {
    guard let sourceTag = try getTagRecord(for: from) else {
      throw IndxError.InvalidParameter("No tag found for value \(from)")
    }

    guard let targetTag = try getTagRecord(for: into) else {
      throw IndxError.InvalidParameter("No tag found for value \(into)")
    }

    return try consolidateTag(fromTag: sourceTag, intoTag: targetTag)
  }
}

extension String.StringInterpolation {
  mutating func appendInterpolation(_ filter: FilteringTag) {
    appendInterpolation("'\(filter.rawValue)'")
  }
}
