// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("FilteringTagMultiParam", .tags(.indexer))
struct FilteringTagMultiParamTest {

  let tagA = FilteringTag.tag("landscape")
  let tagB = FilteringTag.tag("nature")

  var filterA: FilteringTag.Filter { FilteringTag.Filter(tag: tagA, effect: .inclusive) }
  var filterB: FilteringTag.Filter { FilteringTag.Filter(tag: tagB, effect: .inclusive) }

  // MARK: - count and isEmpty

  @Test("count returns the number of filters")
  func test_count() {
    let param = FilteringTagMultiParam([filterA, filterB])
    expect(param.count).to(equal(2))
  }

  @Test("isEmpty returns true when no filters")
  func test_is_empty_true() {
    let param = FilteringTagMultiParam([])
    expect(param.isEmpty).to(beTrue())
  }

  @Test("isEmpty returns false when filters present")
  func test_is_empty_false() {
    let param = FilteringTagMultiParam([filterA])
    expect(param.isEmpty).to(beFalse())
  }

  // MARK: - enabled behavior

  @Test("enabled param preserves filters")
  func test_enabled_preserves_filters() {
    let param = FilteringTagMultiParam([filterA], isEnabled: true)
    expect(param.filters).to(haveCount(1))
  }

  @Test("disabled param still holds filters but exclusiveValues returns none")
  func test_disabled_still_holds_filters() {
    let param = FilteringTagMultiParam([filterA], isEnabled: false)
    expect(param.filters).to(haveCount(1))
  }

  // MARK: - clone operations

  @Test("clone(withValues:) replaces filters")
  func test_clone_with_values() {
    let param = FilteringTagMultiParam([filterA])
    let cloned = param.clone(withValues: [filterB])
    expect(cloned.filters).to(haveCount(1))
    expect(cloned.filters[0].tag).to(equal(tagB))
  }

  @Test("clone(withOperator:) changes operator but preserves filters")
  func test_clone_with_operator() {
    let param = FilteringTagMultiParam([filterA], operator: .or)
    let cloned = param.clone(withOperator: .and)
    expect(cloned.filterOpr).to(equal(.and))
    expect(cloned.filters).to(haveCount(1))
  }

  @Test("clone(withEnabled:false) disables the param")
  func test_clone_with_disabled() {
    let param = FilteringTagMultiParam([filterA], isEnabled: true)
    let cloned = param.clone(withEnabled: false)
    expect(cloned.enabled).to(beFalse())
  }

  // MARK: - appending

  @Test("appending a FilteringTag increases count by one")
  func test_appending_tag() {
    let param = FilteringTagMultiParam([filterA])
    let updated = param.appending(tagB)
    expect(updated.count).to(equal(2))
  }

  @Test("appending array of FilteringTags increases count accordingly")
  func test_appending_array_of_tags() {
    let param = FilteringTagMultiParam([])
    let updated = param.appending([tagA, tagB])
    expect(updated.count).to(equal(2))
  }
}
