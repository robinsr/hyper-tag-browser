// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("SearchTerm", .tags(.dataModel))
struct SearchTermTest {

  // MARK: - Initialization

  @Test("init(value:kind:) preserves value and kind")
  func test_init_value_kind() {
    let term = SearchTerm(value: "sunset", kind: .related)
    expect(term.value).to(equal("sunset"))
    expect(term.kind).to(equal(.related))
  }

  @Test("init from plain string gives related kind")
  func test_init_plain_string() {
    let term = SearchTerm("sunset")
    expect(term.value).to(equal("sunset"))
    expect(term.kind).to(equal(.related))
  }

  @Test("init from # prefix gives tag kind")
  func test_init_hash_prefix() {
    let term = SearchTerm("#landscape")
    expect(term.value).to(equal("landscape"))
    expect(term.kind).to(equal(.tag))
  }

  @Test("init from @ prefix gives artist kind")
  func test_init_at_prefix() {
    let term = SearchTerm("@photographer")
    expect(term.value).to(equal("photographer"))
    expect(term.kind).to(equal(.artist))
  }

  @Test("searchPredicate returns a SearchQueryFragment")
  func test_search_predicate() {
    let term = SearchTerm(value: "sunset", kind: .related)
    let pred = term.searchPredicate
    expect(pred.queryString).notTo(beEmpty())
  }

  // MARK: - Matcher.matchOne

  @Test("matchOne returns plain word as related kind")
  func test_matchone_plain_word() {
    let (value, kind) = SearchTerm.Matcher.matchOne(in: "sunset")
    expect(value).to(equal("sunset"))
    expect(kind).to(equal(.related))
  }

  @Test("matchOne parses # prefix as tag kind")
  func test_matchone_hash_prefix() {
    let (value, kind) = SearchTerm.Matcher.matchOne(in: "#landscape")
    expect(value).to(equal("landscape"))
    expect(kind).to(equal(.tag))
  }

  @Test("matchOne parses @ prefix as artist kind")
  func test_matchone_at_prefix() {
    let (value, kind) = SearchTerm.Matcher.matchOne(in: "@ansel")
    expect(value).to(equal("ansel"))
    expect(kind).to(equal(.artist))
  }

  @Test("matchOne parses full brace form value correctly")
  func test_matchone_full_brace_form() {
    let (value, _) = SearchTerm.Matcher.matchOne(in: "{artist:Ansel Adams}")
    expect(value).to(equal("Ansel Adams"))
  }

  // MARK: - Matcher.matchAll

  @Test("matchAll on single word returns one result")
  func test_matchall_single_word() {
    let results = SearchTerm.Matcher.matchAll(in: "sunset")
    expect(results).to(haveCount(1))
    expect(results[0].0).to(equal("sunset"))
  }

  @Test("matchAll on multiple tokens returns multiple results")
  func test_matchall_multiple_tokens() {
    let results = SearchTerm.Matcher.matchAll(in: "#landscape @ansel")
    expect(results.count).to(beGreaterThanOrEqualTo(2))
  }

  @Test("matchAll extracts correct values from prefixed tokens")
  func test_matchall_prefixed_token_values() {
    let results = SearchTerm.Matcher.matchAll(in: "#mountain")
    let match = results.first
    expect(match?.0).to(equal("mountain"))
    expect(match?.1).to(equal(.tag))
  }
}
