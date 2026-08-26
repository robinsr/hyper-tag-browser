// created on 2026-08-26 by robinsr

import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("GRDBSaves", .serialized, .tags(.indexer))
struct GRDBSavesTest {

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("listSavedQueries returns empty array initially")
  func test_list_saved_queries_empty() async throws {
    let results = try await service.listSavedQueries()
    expect(results).to(beEmpty())
  }

  @Test("createSavedQuery persists and returns a record with non-empty id")
  func test_create_saved_query() async throws {
    let filters = BrowseFilters()
    let record = try await service.createSavedQuery(named: "My Query", using: filters)
    expect(record.id).notTo(beEmpty())
    expect(record.name).to(equal("My Query"))
  }

  @Test("getSavedQuery(withId:) returns nil for unknown id")
  func test_get_saved_query_nil_for_unknown() async throws {
    let result = try await service.getSavedQuery(withId: "unknown-id-does-not-exist")
    expect(result).to(beNil())
  }

  @Test("getSavedQuery(withId:) returns record after creation")
  func test_get_saved_query_after_create() async throws {
    let filters = BrowseFilters()
    let created = try await service.createSavedQuery(named: "Find Query", using: filters)
    let fetched = try await service.getSavedQuery(withId: created.id)
    expect(fetched?.id).to(equal(created.id))
    expect(fetched?.name).to(equal("Find Query"))
  }

  @Test("listSavedQueries returns the created record")
  func test_list_saved_queries_after_create() async throws {
    let filters = BrowseFilters()
    let created = try await service.createSavedQuery(named: "Listed Query", using: filters)
    let results = try await service.listSavedQueries()
    let ids = results.map(\.id)
    expect(ids).to(contain(created.id))
  }

  @Test("updateSavedQuery changes the query, id remains unchanged")
  func test_update_saved_query() async throws {
    let filters = BrowseFilters()
    let created = try await service.createSavedQuery(named: "Original Query", using: filters)
    var updatedFilters = BrowseFilters()
    updatedFilters._nudge = 1
    let updated = try await service.updateSavedQuery(withId: created.id, using: updatedFilters)
    expect(updated.id).to(equal(created.id))
  }

  @Test("renameSavedQuery changes the name, id remains unchanged")
  func test_rename_saved_query() async throws {
    let filters = BrowseFilters()
    let created = try await service.createSavedQuery(named: "Before Rename", using: filters)
    let renamed = try await service.renameSavedQuery(withId: created.id, to: "After Rename")
    expect(renamed.id).to(equal(created.id))
    expect(renamed.name).to(equal("After Rename"))
  }

  @Test("deleteSavedQuery removes the record")
  func test_delete_saved_query() async throws {
    let filters = BrowseFilters()
    let created = try await service.createSavedQuery(named: "To Delete", using: filters)
    let deleted = try await service.deleteSavedQuery(withId: created.id)
    expect(deleted).to(beTrue())
    let fetched = try await service.getSavedQuery(withId: created.id)
    expect(fetched).to(beNil())
  }
}
