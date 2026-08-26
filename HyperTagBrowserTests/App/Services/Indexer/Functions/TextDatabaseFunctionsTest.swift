// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("TextDatabaseFunctions", .tags(.indexer))
struct TextDatabaseFunctionsTest {

  // MARK: - textConcat

  @Test("textConcat joins all strings with no separator")
  func test_text_concat_joins() {
    let result = TextDBFunctions.execTextConcat(["hello", " ", "world"])
    expect(result as? String).to(equal("hello world"))
  }

  @Test("textConcat returns empty string for empty input")
  func test_text_concat_empty_input() {
    let result = TextDBFunctions.execTextConcat([])
    expect(result as? String).to(equal(""))
  }

  @Test("textConcat returns single value for single-element input")
  func test_text_concat_single_element() {
    let result = TextDBFunctions.execTextConcat(["only"])
    expect(result as? String).to(equal("only"))
  }

  @Test("textConcat skips nil values")
  func test_text_concat_skips_nils() {
    let result = TextDBFunctions.execTextConcat([Optional<String>.none, "a", Optional<String>.none, "b"])
    expect(result as? String).to(equal("ab"))
  }

  @Test("textConcat preserves whitespace")
  func test_text_concat_preserves_whitespace() {
    let result = TextDBFunctions.execTextConcat(["  leading", " middle ", "trailing  "])
    expect(result as? String).to(equal("  leading middle trailing  "))
  }

  // MARK: - textJoin

  @Test("textJoin uses first arg as separator")
  func test_text_join_with_separator() {
    let result = TextDBFunctions.execTextJoin(["-", "a", "b", "c"])
    expect(result as? String).to(equal("a-b-c"))
  }

  @Test("textJoin with empty separator concatenates values")
  func test_text_join_empty_separator() {
    let result = TextDBFunctions.execTextJoin(["", "foo", "bar"])
    expect(result as? String).to(equal("foobar"))
  }

  @Test("textJoin with single value after separator returns that value")
  func test_text_join_single_value() {
    let result = TextDBFunctions.execTextJoin(["-", "only"])
    expect(result as? String).to(equal("only"))
  }

  @Test("textJoin with multi-character separator")
  func test_text_join_multi_char_separator() {
    let result = TextDBFunctions.execTextJoin([" :: ", "alpha", "beta", "gamma"])
    expect(result as? String).to(equal("alpha :: beta :: gamma"))
  }

  // MARK: - hashId

  @Test("hashId returns a non-empty string for given inputs")
  func test_hash_id_non_empty() {
    let result = TextDBFunctions.execHashId(["alpha", "beta"])
    expect(result as? String).notTo(beEmpty())
  }

  @Test("hashId is deterministic for same inputs")
  func test_hash_id_deterministic() {
    let r1 = TextDBFunctions.execHashId(["same", "inputs"]) as? String
    let r2 = TextDBFunctions.execHashId(["same", "inputs"]) as? String
    expect(r1).to(equal(r2))
  }

  @Test("hashId produces different results for different inputs")
  func test_hash_id_different_inputs() {
    let r1 = TextDBFunctions.execHashId(["input-one"]) as? String
    let r2 = TextDBFunctions.execHashId(["input-two"]) as? String
    expect(r1).notTo(equal(r2))
  }

  @Test("hashId returns a non-empty string for a single input")
  func test_hash_id_single_input() {
    let result = TextDBFunctions.execHashId(["solo"])
    expect(result as? String).notTo(beEmpty())
  }

  @Test("hashId treats concatenated inputs the same as separate inputs")
  func test_hash_id_concatenation_equivalence() {
    // execHashId joins all inputs before hashing, so ["ab"] == ["a", "b"]
    let combined = TextDBFunctions.execHashId(["ab"]) as? String
    let separate = TextDBFunctions.execHashId(["a", "b"]) as? String
    expect(combined).to(equal(separate))
  }

  @Test("hashId skips nil values")
  func test_hash_id_skips_nils() {
    let withNils = TextDBFunctions.execHashId([Optional<String>.none, "value", Optional<String>.none]) as? String
    let withoutNils = TextDBFunctions.execHashId(["value"]) as? String
    expect(withNils).to(equal(withoutNils))
  }
}
