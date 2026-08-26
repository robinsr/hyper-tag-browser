// created on 8/26/26 by robinsr

import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("ListIndexesRequest", .serialized, .tags(.indexer, .indexRecord))
struct ListIndexesRequestTest {

  private typealias Indx = IndexRecordFixture

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("returns empty array when contentIds is empty")
  func test_empty_content_ids_returns_empty() async throws {
    let request = ListIndexesRequest(contentIds: [])

    let results = try await queue.read { db in
      try request.fetch(db)
    }

    expect(results).to(beEmpty())
  }

  @Test("returns matching IndexInfoRecords for given contentIds")
  func test_returns_records_for_given_ids() async throws {
    let expectedIds = [Indx.Cases.bakery.id, Indx.Cases.bbq.id]
    let request = ListIndexesRequest(contentIds: expectedIds)

    let results = try await queue.read { db in
      try request.fetch(db)
    }

    expect(results).to(haveCount(expectedIds.count))
    expect(results.map(\.id)).to(contain(expectedIds))
  }

  @Test("returns all records when all contentIds are provided")
  func test_all_ids_returns_all_records() async throws {
    let allIds = Indx.Cases.allCases.map(\.id)
    let request = ListIndexesRequest(contentIds: allIds)

    let results = try await queue.read { db in
      try request.fetch(db)
    }

    expect(results).to(haveCount(allIds.count))
    expect(results.map(\.id).asSet).to(equal(allIds.asSet))
  }

  @Test("returns single record when one contentId is provided")
  func test_single_id_returns_single_record() async throws {
    let expectedId = Indx.Cases.diner.id
    let request = ListIndexesRequest(contentIds: [expectedId])

    let results = try await queue.read { db in
      try request.fetch(db)
    }

    expect(results).to(haveCount(1))
    expect(results.first?.id).to(equal(expectedId))
  }

  @Test("returned records include tag values")
  func test_records_include_tag_associations() async throws {
    let bakeryId = Indx.Cases.bakery.id
    let request = ListIndexesRequest(contentIds: [bakeryId])

    let results = try await queue.read { db in
      try request.fetch(db)
    }

    guard let bakery = results.first else {
      fail("Expected a result for bakery")
      return
    }

    // bakery fixture has 4 food tags: donuts, cake, cookies, pie
    expect(bakery.tagValues).toNot(beEmpty())
    expect(bakery.tagCount).to(beGreaterThan(0))
  }

  @Test("returns empty for non-existent contentIds")
  func test_nonexistent_ids_returns_empty() async throws {
    let nonexistentId = ContentId(existing: "content:doesnotexist")
    let request = ListIndexesRequest(contentIds: [nonexistentId])

    let results = try await queue.read { db in
      try request.fetch(db)
    }

    expect(results).to(beEmpty())
  }

  @Test("hidden records are included when their id is requested")
  func test_hidden_records_are_fetched_by_id() async throws {
    // coffeeshop fixture has visibility: .hidden
    let hiddenId = Indx.Cases.coffeeshop.id
    let request = ListIndexesRequest(contentIds: [hiddenId])

    let results = try await queue.read { db in
      try request.fetch(db)
    }

    expect(results).to(haveCount(1))
    expect(results.first?.id).to(equal(hiddenId))
  }
}
