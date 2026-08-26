// created on 8/26/26 by robinsr

import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("RegexpDatabaseFunctions", .tags(.indexer))
struct RegexpDatabaseFunctionsTest {

  // MARK: - regexpMatch

  @Test("regexpMatch returns true for matching input")
  func test_regexp_match_true() {
    let result = RegexpDBFunctions.execRegexpMatch(["hello world", "hello .*"])
    expect(result as? Bool).to(beTrue())
  }

  @Test("regexpMatch returns false for non-matching input")
  func test_regexp_match_false() {
    let result = RegexpDBFunctions.execRegexpMatch(["hello world", "^goodbye"])
    expect(result as? Bool).to(beFalse())
  }

  @Test("regexpMatch returns nil for nil string input")
  func test_regexp_match_nil_input() {
    let result = RegexpDBFunctions.execRegexpMatch([Optional<String>.none, ".*"])
    expect(result).to(beNil())
  }

  @Test("regexpMatch returns nil for invalid pattern")
  func test_regexp_match_invalid_pattern() {
    let result = RegexpDBFunctions.execRegexpMatch(["hello", "[invalid"])
    expect(result).to(beNil())
  }

  @Test("regexpMatch matches case-sensitively")
  func test_regexp_match_case_sensitive() {
    let resultLower = RegexpDBFunctions.execRegexpMatch(["Hello", "hello"])
    let resultUpper = RegexpDBFunctions.execRegexpMatch(["Hello", "Hello"])
    expect(resultLower as? Bool).to(beFalse())
    expect(resultUpper as? Bool).to(beTrue())
  }

  // MARK: - regexpCapture

  @Test("regexpCapture returns the first capture group")
  func test_regexp_capture_group_0() {
    let result = RegexpDBFunctions.execRegexpCapture(["[photography] sunset", #"\[(.*)\]"#, 0])
    expect(result as? String).to(equal("photography"))
  }

  @Test("regexpCapture returns nil when pattern does not match")
  func test_regexp_capture_no_match() {
    let result = RegexpDBFunctions.execRegexpCapture(["hello", #"\[(.*)\]"#, 0])
    expect(result).to(beNil())
  }

  @Test("regexpCapture returns nil for nil string input")
  func test_regexp_capture_nil_input() {
    let result = RegexpDBFunctions.execRegexpCapture([Optional<String>.none, #"\[(.*)\]"#, 0])
    expect(result).to(beNil())
  }

  @Test("regexpCapture returns nil for invalid pattern")
  func test_regexp_capture_invalid_pattern() {
    let result = RegexpDBFunctions.execRegexpCapture(["hello", "[invalid", 0])
    expect(result).to(beNil())
  }

  @Test("regexpCapture returns nil when capture group index is out of bounds")
  func test_regexp_capture_out_of_bounds_index() {
    let result = RegexpDBFunctions.execRegexpCapture(["[photography] sunset", #"\[(.*)\]"#, 5])
    expect(result).to(beNil())
  }

  // MARK: - regexpReplace

  @Test("regexpReplace returns replacement string when pattern matches")
  func test_regexp_replace_matches() {
    let result = RegexpDBFunctions.execRegexpReplace(["hello world", "world", "earth"])
    expect(result as? String).to(equal("earth"))
  }

  @Test("regexpReplace returns nil when pattern does not match")
  func test_regexp_replace_no_match() {
    let result = RegexpDBFunctions.execRegexpReplace(["hello", "^goodbye", "hi"])
    expect(result).to(beNil())
  }

  @Test("regexpReplace returns nil for nil string input")
  func test_regexp_replace_nil_input() {
    let result = RegexpDBFunctions.execRegexpReplace([Optional<String>.none, "world", "earth"])
    expect(result).to(beNil())
  }

  @Test("regexpReplace returns nil for invalid pattern")
  func test_regexp_replace_invalid_pattern() {
    let result = RegexpDBFunctions.execRegexpReplace(["hello", "[invalid", "replacement"])
    expect(result).to(beNil())
  }
}
