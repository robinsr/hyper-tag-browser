// created on 2026-08-26 by robinsr

import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("ListBookmarksRequest", .serialized, .tags(.indexer))
struct ListBookmarksRequestTest {

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("returns empty list when no bookmarks exist")
  func test_empty_when_none() async throws {
    let request = ListBookmarksRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(beEmpty())
  }

  @Test("returns inserted bookmark in results")
  func test_returns_single_bookmark() async throws {
    let contentId = IndexRecordFixture.Cases.bakery.id
    let _ = try await service.createBookmark(to: contentId)

    let request = ListBookmarksRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(haveCount(1))
    expect(results.first?.bookmark.contentId).to(equal(contentId))
  }

  @Test("returns all bookmarks when multiple exist")
  func test_returns_multiple_bookmarks() async throws {
    let id1 = IndexRecordFixture.Cases.bakery.id
    let id2 = IndexRecordFixture.Cases.diner.id
    let id3 = IndexRecordFixture.Cases.bbq.id
    let _ = try await service.createBookmark(to: id1)
    let _ = try await service.createBookmark(to: id2)
    let _ = try await service.createBookmark(to: id3)

    let request = ListBookmarksRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(haveCount(3))

    let contentIds = results.map { $0.bookmark.contentId }
    expect(contentIds).to(contain(id1, id2, id3))
  }

  @Test("result records include joined content info")
  func test_result_includes_content() async throws {
    let contentId = IndexRecordFixture.Cases.coffeeshop.id
    let _ = try await service.createBookmark(to: contentId)

    let request = ListBookmarksRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(haveCount(1))

    let result = try #require(results.first)
    expect(result.content.id).to(equal(contentId))
    expect(result.bookmark.contentId).to(equal(contentId))
  }
}
