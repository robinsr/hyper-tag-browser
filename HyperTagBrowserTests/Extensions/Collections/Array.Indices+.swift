// created on 4/28/25 by robinsr

import Testing

@testable import HyperTagBrowser



@Suite("Array+subscript(wrapping:)")
struct ExtensionArrayIndicesTests {
  
  let letters: [String] = ["a", "b", "c", "d"]

  @Test("Index in range")
  func test_array_subscript_wrapping_inrange() async throws {
    // Sanity check - first and last
    #expect(letters[letters.indices.first!] == "a")
    #expect(letters[letters.indices.last!] == "d")
    
    // Sanity check - valid indices access expected items
    #expect(letters[wrapping: 0] == "a")
    #expect(letters[wrapping: 1] == "b")
    #expect(letters[wrapping: 2] == "c")
    #expect(letters[wrapping: 3] == "d")
  }
  
  @Test("Positive index out of range")
  func test_array_subscript_wrapping_overtop() async throws {
    #expect(letters[wrapping: 4] == "a")
    #expect(letters[wrapping: 5] == "b")
    #expect(letters[wrapping: 6] == "c")
    #expect(letters[wrapping: 7] == "d")
  }
  
  @Test("Negative index out of range")
  func test_array_subscript_wrapping_under() async throws {
    #expect(letters[wrapping: -1] == "d")
    #expect(letters[wrapping: -2] == "c")
    #expect(letters[wrapping: -3] == "b")
    #expect(letters[wrapping: -4] == "a")
    #expect(letters[wrapping: -5] == "d")
  }
}
