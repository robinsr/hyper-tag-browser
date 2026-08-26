// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("SearchQuery", .tags(.dataModel))
struct SearchQueryTest {

  // MARK: - Predicate

  @Test("Predicate queryString includes lhs attribute name")
  func test_predicate_includes_lhs() {
    let pred = SearchQuery.Predicate(lhs: "domainIdentifier", rhs: "com.example", compare: .equalTo)
    expect(pred.queryString).to(contain("domainIdentifier"))
  }

  @Test("Predicate queryString includes rhs value")
  func test_predicate_includes_rhs() {
    let pred = SearchQuery.Predicate(lhs: "title", rhs: "sunset", compare: .equalTo)
    expect(pred.queryString).to(contain("sunset"))
  }

  @Test("Predicate equalTo uses == operator")
  func test_predicate_equal_to_operator() {
    let pred = SearchQuery.Predicate(lhs: "attr", rhs: "val", compare: .equalTo)
    expect(pred.queryString).to(contain("=="))
  }

  @Test("Predicate with caseInsensitive modifier appends c to queryString")
  func test_predicate_case_insensitive_modifier() {
    let pred = SearchQuery.Predicate(
      lhs: "title", rhs: "sunset", compare: .like, modifiers: [.caseInsensitive])
    expect(pred.queryString).to(contain("c"))
  }

  @Test("Predicate nsPredicate is NSComparisonPredicate")
  func test_predicate_nspredicate_type() {
    let pred = SearchQuery.Predicate(lhs: "attr", rhs: "val", compare: .equalTo)
    expect(pred.nsPredicate).to(beAnInstanceOf(NSComparisonPredicate.self))
  }

  // MARK: - Compound

  @Test("Compound with two predicates contains both attribute names")
  func test_compound_contains_both_attributes() {
    let a = SearchQuery.Predicate(lhs: "title", rhs: "alpha", compare: .equalTo)
    let b = SearchQuery.Predicate(lhs: "contentType", rhs: "image", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .and, statements: [a, b])
    expect(compound.queryString).to(contain("title"))
    expect(compound.queryString).to(contain("contentType"))
  }

  @Test("Compound with .and operator uses && token")
  func test_compound_and_operator() {
    let a = SearchQuery.Predicate(lhs: "a", rhs: "1", compare: .equalTo)
    let b = SearchQuery.Predicate(lhs: "b", rhs: "2", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .and, statements: [a, b])
    expect(compound.queryString).to(contain("&&"))
  }

  @Test("Compound with .or operator uses || token")
  func test_compound_or_operator() {
    let a = SearchQuery.Predicate(lhs: "a", rhs: "1", compare: .equalTo)
    let b = SearchQuery.Predicate(lhs: "b", rhs: "2", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .or, statements: [a, b])
    expect(compound.queryString).to(contain("||"))
  }

  @Test("Compound with empty statements produces empty-parens queryString")
  func test_compound_empty_statements() {
    let compound = SearchQuery.Compound(opr: .and, statements: [])
    expect(compound.queryString).to(equal("()"))
  }

  @Test("Compound nsPredicate is NSCompoundPredicate")
  func test_compound_nspredicate_type() {
    let a = SearchQuery.Predicate(lhs: "a", rhs: "1", compare: .equalTo)
    let compound = SearchQuery.Compound(opr: .and, statements: [a])
    expect(compound.nsPredicate).to(beAnInstanceOf(NSCompoundPredicate.self))
  }

  // MARK: - Builder

  @Test("Builder with single item produces Compound with one statement")
  func test_builder_single_item() {
    let pred = SearchQuery.Predicate(lhs: "title", rhs: "sunset", compare: .equalTo)
    let compound = SearchQuery.Builder().with(pred).build()
    expect(compound.statements).to(haveCount(1))
  }

  @Test("Builder with array of items produces Compound with all statements")
  func test_builder_multiple_items() {
    let a = SearchQuery.Predicate(lhs: "title", rhs: "alpha", compare: .equalTo)
    let b = SearchQuery.Predicate(lhs: "title", rhs: "beta", compare: .equalTo)
    let compound = SearchQuery.Builder().with([a, b]).build()
    expect(compound.statements).to(haveCount(2))
  }

  @Test("Builder default operator is .and")
  func test_builder_default_operator_is_and() {
    let compound = SearchQuery.Builder().build()
    expect(compound.opr).to(equal(.and))
  }
}
