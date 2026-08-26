// created on 2026-08-26 by robinsr

import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("ListSavedQueriesRequest", .serialized, .tags(.indexer))
struct ListSavedQueriesRequestTest {

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("returns empty list when no saved queries exist")
  func test_empty_when_none() async throws {
    let request = ListSavedQueriesRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(beEmpty())
  }

  @Test("returns all saved queries after insertion")
  func test_returns_all() async throws {
    try await queue.write { db in
      var filters1 = BrowseFilters()
      filters1._nudge = 1
      var filters2 = BrowseFilters()
      filters2._nudge = 2
      let q1 = SavedQueryRecord(name: "Alpha", query: filters1)
      let q2 = SavedQueryRecord(name: "Beta", query: filters2)
      try q1.insert(db)
      try q2.insert(db)
    }

    let request = ListSavedQueriesRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(haveCount(2))
  }

  @Test("results are ordered by createdAt descending (newest first)")
  func test_order_newest_first() async throws {
    let older = Date(timeIntervalSinceNow: -3600)
    let newer = Date(timeIntervalSinceNow: -60)

    try await queue.write { db in
      var olderFilters = BrowseFilters()
      olderFilters._nudge = 10
      var newerFilters = BrowseFilters()
      newerFilters._nudge = 20
      let q1 = SavedQueryRecord(id: olderFilters.id, name: "Older", query: olderFilters, createdAt: older, updatedAt: older)
      let q2 = SavedQueryRecord(id: newerFilters.id, name: "Newer", query: newerFilters, createdAt: newer, updatedAt: newer)
      try q1.insert(db)
      try q2.insert(db)
    }

    let request = ListSavedQueriesRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results.first?.name).to(equal("Newer"))
    expect(results.last?.name).to(equal("Older"))
  }

  @Test("limit property caps the number of results returned")
  func test_limit_caps_results() async throws {
    try await queue.write { db in
      for i in 1...5 {
        var filters = BrowseFilters()
        filters._nudge = i
        let q = SavedQueryRecord(name: "Query \(i)", query: filters)
        try q.insert(db)
      }
    }

    let request = ListSavedQueriesRequest(limit: 3)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(haveCount(3))
  }

  @Test("default limit of 10 returns all when count is under the limit")
  func test_default_limit_returns_all_under_threshold() async throws {
    try await queue.write { db in
      for i in 1...7 {
        var filters = BrowseFilters()
        filters._nudge = i
        let q = SavedQueryRecord(name: "Query \(i)", query: filters)
        try q.insert(db)
      }
    }

    let request = ListSavedQueriesRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(haveCount(7))
  }
}
