// created on 8/26/26 by robinsr

import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("ListCountedTagsRequest", .serialized, .tags(.indexer, .tagRecord))
struct ListCountedTagsRequestTest {

  private typealias Tags = TagRecordFixture

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("returns non-empty list when tags are present in the default domain")
  func test_returns_tags() async throws {
    let request = ListCountedTagsRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).notTo(beEmpty())
  }

  @Test("every result has a count greater than or equal to zero")
  func test_counts_are_non_negative() async throws {
    let request = ListCountedTagsRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(allPass { $0.count >= 0 })
  }

  @Test("results are sorted by count descending")
  func test_results_sorted_by_count_descending() async throws {
    let request = ListCountedTagsRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    let counts = results.map(\.count)
    expect(counts).to(equal(counts.sorted(by: >)))
  }

  @Test("itemLimit parameter is respected")
  func test_item_limit_is_respected() async throws {
    let limit = 3
    var params = TagQueryParameters(query: "", itemLimit: limit)
    let request = ListCountedTagsRequest(parameters: params)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results.count).to(beLessThanOrEqualTo(limit))
  }

  @Test("query text filters results by tag value")
  func test_query_text_filters_results() async throws {
    // "pie" should match the "pie" tag fixture
    let params = TagQueryParameters(query: "pie", itemLimit: 25)
    let request = ListCountedTagsRequest(parameters: params)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).notTo(beEmpty())
    expect(results).to(allPass { $0.tag.tagValue.lowercased().contains("pie") })
  }

  @Test("query text returns empty when no tags match")
  func test_query_text_no_match_returns_empty() async throws {
    let params = TagQueryParameters(query: "zzznomatch999", itemLimit: 25)
    let request = ListCountedTagsRequest(parameters: params)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results).to(beEmpty())
  }

  @Test("excludingTags parameter removes specified tags from results")
  func test_excluding_tags_filters_results() async throws {
    let excludedTag = Tags.Cases.donuts.asFilter
    let params = TagQueryParameters(
      query: "",
      excludingTags: [excludedTag],
      itemLimit: 25
    )
    let request = ListCountedTagsRequest(parameters: params)
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results.map(\.asFilter)).notTo(contain(excludedTag))
  }

  @Test("restricting to attribution domain returns creator-type tags")
  func test_attribution_domain_returns_creator_tags() async throws {
    let params = TagQueryParameters(
      query: "",
      domains: [.attribution],
      itemLimit: 25
    )
    let request = ListCountedTagsRequest(parameters: params)
    let results = try await queue.read { db in try request.fetch(db) }
    // All creator fixture tags (chef, baker, grillmaster, barista) are attribution domain
    expect(results).notTo(beEmpty())
    expect(results.map(\.asFilter)).to(allPass { $0.type.domain == .attribution })
  }

  @Test("default parameters only return descriptive domain tags")
  func test_default_domain_is_descriptive() async throws {
    let request = ListCountedTagsRequest()
    let results = try await queue.read { db in try request.fetch(db) }
    expect(results.map(\.asFilter)).to(allPass { $0.type.domain == .descriptive })
  }
}
