// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("TagQueryParameters", .tags(.indexer))
struct TagQueryParametersTest {

  // MARK: - queryText normalization

  @Test("queryText is trimmed of leading/trailing whitespace")
  func test_query_text_trimmed() {
    let params = TagQueryParameters(query: "  landscape  ")
    expect(params.queryText).to(equal("landscape"))
  }

  @Test("queryText is lowercased")
  func test_query_text_lowercased() {
    let params = TagQueryParameters(query: "LANDSCAPE")
    expect(params.queryText).to(equal("landscape"))
  }

  @Test("queryText trims and lowercases together")
  func test_query_text_trim_and_lower() {
    let params = TagQueryParameters(query: "  NATIONAL PARK  ")
    expect(params.queryText).to(equal("national park"))
  }

  // MARK: - isEmpty

  @Test("isEmpty returns true for empty query string")
  func test_is_empty_true() {
    let params = TagQueryParameters(query: "")
    expect(params.isEmpty).to(beTrue())
  }

  @Test("isEmpty returns false for non-empty query string")
  func test_is_empty_false() {
    let params = TagQueryParameters(query: "landscape")
    expect(params.isEmpty).to(beFalse())
  }

  @Test("isEmpty returns true for whitespace-only query")
  func test_is_empty_whitespace() {
    let params = TagQueryParameters(query: "   ")
    expect(params.isEmpty).to(beTrue())
  }

  // MARK: - defaults

  @Test("default domain is descriptive")
  func test_default_domain() {
    let params = TagQueryParameters(query: "test")
    expect(params.tagDomains).to(equal([.descriptive]))
  }

  @Test("default itemLimit is 10")
  func test_default_item_limit() {
    let params = TagQueryParameters(query: "test")
    expect(params.itemLimit).to(equal(10))
  }

  @Test("excludingTags defaults to empty")
  func test_excluding_tags_default_empty() {
    let params = TagQueryParameters(query: "test")
    expect(params.excludingTags).to(beEmpty())
  }

  @Test("excludingContent defaults to empty")
  func test_excluding_content_default_empty() {
    let params = TagQueryParameters(query: "test")
    expect(params.excludingContent).to(beEmpty())
  }

  // MARK: - custom values

  @Test("custom itemLimit is preserved")
  func test_custom_item_limit() {
    let params = TagQueryParameters(query: "test", itemLimit: 25)
    expect(params.itemLimit).to(equal(25))
  }

  @Test("custom excludingTags are preserved")
  func test_custom_excluding_tags() {
    let tag = FilteringTag.tag("excluded")
    let params = TagQueryParameters(query: "test", excludingTags: [tag])
    expect(params.excludingTags).to(equal([tag]))
  }
}
