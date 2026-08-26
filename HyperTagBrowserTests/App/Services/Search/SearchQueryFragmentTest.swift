// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("SearchQueryFragment", .tags(.dataModel))
struct SearchQueryFragmentTest {

  // MARK: - Predicate queryString format

  @Test("Predicate equalTo produces == in queryString")
  func test_predicate_equalto_operator_string() {
    let pred = SearchQuery.Predicate(lhs: "attr", rhs: "val", compare: .equalTo)
    expect(pred.queryString).to(contain("=="))
  }

  @Test("Predicate like produces = in queryString")
  func test_predicate_like_operator_string() {
    let pred = SearchQuery.Predicate(lhs: "title", rhs: "sunset", compare: .like)
    let qs = pred.queryString
    expect(qs).to(contain("="))
    expect(qs).notTo(contain("=="))
  }

  @Test("Predicate with caseInsensitive modifier appends c modifier")
  func test_predicate_modifier_appended() {
    let pred = SearchQuery.Predicate(
      lhs: "title", rhs: "test", compare: .like, modifiers: [.caseInsensitive])
    expect(pred.queryString).to(contain("c"))
  }

  @Test("Predicate with no modifiers has no modifier suffix")
  func test_predicate_no_modifiers() {
    let pred = SearchQuery.Predicate(lhs: "attr", rhs: "val", compare: .equalTo, modifiers: [])
    let qs = pred.queryString
    expect(qs).notTo(endWith("c"))
    expect(qs).notTo(endWith("d"))
  }

  // MARK: - Compound queryString format

  @Test("Compound .and joins with && token")
  func test_compound_and_token() {
    let a = SearchQuery.Predicate(lhs: "a", rhs: "1", compare: .equalTo)
    let b = SearchQuery.Predicate(lhs: "b", rhs: "2", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .and, statements: [a, b])
    expect(compound.queryString).to(contain("&&"))
  }

  @Test("Compound .or joins with || token")
  func test_compound_or_token() {
    let a = SearchQuery.Predicate(lhs: "a", rhs: "1", compare: .equalTo)
    let b = SearchQuery.Predicate(lhs: "b", rhs: "2", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .or, statements: [a, b])
    expect(compound.queryString).to(contain("||"))
  }

  @Test("Compound single statement queryString contains the predicate's attribute")
  func test_compound_single_statement() {
    let pred = SearchQuery.Predicate(lhs: "title", rhs: "val", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .and, statements: [pred])
    expect(compound.queryString).to(contain("title"))
  }

  // MARK: - nsPredicate types

  @Test("Predicate nsPredicate is NSComparisonPredicate")
  func test_predicate_nspredicate_is_comparison() {
    let pred = SearchQuery.Predicate(lhs: "attr", rhs: "val", compare: .equalTo)
    expect(pred.nsPredicate).to(beAnInstanceOf(NSComparisonPredicate.self))
  }

  @Test("Compound nsPredicate is NSCompoundPredicate")
  func test_compound_nspredicate_is_compound() {
    let a = SearchQuery.Predicate(lhs: "a", rhs: "1", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .and, statements: [a])
    expect(compound.nsPredicate).to(beAnInstanceOf(NSCompoundPredicate.self))
  }
}
