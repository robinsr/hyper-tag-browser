// created on 2026-08-26 by robinsr

import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("GRDBBookmarks", .serialized, .tags(.indexer))
struct GRDBBookmarksTest {

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("bookmarkExists returns false when no bookmark exists")
  func test_bookmark_exists_false() async throws {
    let contentId = IndexRecordFixture.Cases.bakery.id
    await expect { try await self.service.bookmarkExists(to: contentId) }.to(beFalse())
  }

  @Test("createBookmark persists a bookmark and returns BookmarkInfoRecord")
  func test_create_bookmark() async throws {
    let contentId = IndexRecordFixture.Cases.bakery.id
    let result = try await service.createBookmark(to: contentId)
    expect(result.id).notTo(beEmpty())
    expect(result.bookmark.contentId).to(equal(contentId))
  }

  @Test("bookmarkExists returns true after createBookmark")
  func test_bookmark_exists_true_after_create() async throws {
    let contentId = IndexRecordFixture.Cases.bbq.id
    let _ = try await service.createBookmark(to: contentId)
    await expect { try await self.service.bookmarkExists(to: contentId) }.to(beTrue())
  }

  @Test("createBookmark is idempotent — second call returns existing record")
  func test_create_bookmark_idempotent() async throws {
    let contentId = IndexRecordFixture.Cases.diner.id
    let first = try await service.createBookmark(to: contentId)
    let second = try await service.createBookmark(to: contentId)
    expect(first.id).to(equal(second.id))
  }

  @Test("getBookmark(for:) returns nil when no bookmark exists")
  func test_get_bookmark_returns_nil() async throws {
    let contentId = IndexRecordFixture.Cases.coffeeshop.id
    await expect { try await self.service.getBookmark(for: contentId) }.to(beNil())
  }

  @Test("getBookmark(for:) returns record after createBookmark")
  func test_get_bookmark_after_create() async throws {
    let contentId = IndexRecordFixture.Cases.bakery.id
    let created = try await service.createBookmark(to: contentId)
    let fetched = try await service.getBookmark(for: contentId)
    expect(fetched?.id).to(equal(created.id))
  }

  @Test("deleteBookmark(withId:) removes the record")
  func test_delete_bookmark() async throws {
    let contentId = IndexRecordFixture.Cases.bbq.id
    let created = try await service.createBookmark(to: contentId)
    let _ = try await service.deleteBookmark(withId: created.id)
    await expect { try await self.service.bookmarkExists(to: contentId) }.to(beFalse())
  }

  @Test("deleteBookmarks(to:) removes all bookmarks for a contentId")
  func test_delete_bookmarks_for_content() async throws {
    let contentId = IndexRecordFixture.Cases.diner.id
    let _ = try await service.createBookmark(to: contentId)
    let deleted = try await service.deleteBookmarks(to: contentId)
    expect(deleted).notTo(beEmpty())
    await expect { try await self.service.bookmarkExists(to: contentId) }.to(beFalse())
  }
}
