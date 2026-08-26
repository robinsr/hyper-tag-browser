// created on 8/26/26 by robinsr

import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("ListIndexTagCountRequest", .serialized, .tags(.indexer, .tagRecord))
struct ListIndexTagCountRequestTest {

  private typealias Indx = IndexRecordFixture.Cases

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("returns tag count entries for each provided contentId")
  func test_returns_counts_for_ids() async throws {
    let ids = [Indx.bakery.id, Indx.bbq.id]
    let request = ListIndexTagCountRequest(contentIds: ids)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(Array(results.keys).asSet).to(equal(ids.asSet))
  }

  @Test("returns empty dictionary when given empty contentIds")
  func test_empty_ids_returns_empty() async throws {
    let request = ListIndexTagCountRequest(contentIds: [])
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(beEmpty())
  }

  @Test("bakery tag count matches fixture food tag count")
  func test_bakery_count_matches_fixture() async throws {
    // bakery fixture has 4 food tags: donuts, cake, cookies, pie
    let expectedCount = Indx.bakery.foods.count
    let request = ListIndexTagCountRequest(contentIds: [Indx.bakery.id])
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results[Indx.bakery.id]).to(equal(expectedCount))
  }

  @Test("diner tag count matches fixture food tag count")
  func test_diner_count_matches_fixture() async throws {
    // diner fixture has 6 food tags: pancakes, waffles, soup, chicken, porkchop, pie
    let expectedCount = Indx.diner.foods.count
    let request = ListIndexTagCountRequest(contentIds: [Indx.diner.id])
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results[Indx.diner.id]).to(equal(expectedCount))
  }

  @Test("all tag counts are greater than zero for fixture records")
  func test_all_counts_are_positive() async throws {
    let allIds = Indx.allCases.map(\.id)
    let request = ListIndexTagCountRequest(contentIds: allIds)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(Array(results.values)).to(allPass { $0 > 0 })
  }

  @Test("returns empty for non-existent contentId")
  func test_nonexistent_id_returns_empty() async throws {
    let nonexistentId = ContentId(existing: "content:doesnotexist")
    let request = ListIndexTagCountRequest(contentIds: [nonexistentId])
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(beEmpty())
  }

  @Test("returns counts for all fixture content ids")
  func test_all_fixture_ids_return_counts() async throws {
    let allIds = Indx.allCases.map(\.id)
    let request = ListIndexTagCountRequest(contentIds: allIds)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(Array(results.keys).asSet).to(equal(allIds.asSet))
  }
}
