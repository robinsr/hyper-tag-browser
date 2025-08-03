// created on 4/28/25 by robinsr

import Testing

@testable import TaggedFileBrowser

struct ExtensionArrayIndicesTests {

  @Test("Array.Indices [circular:] - sanity check")
  func test_array_indices_circular() async throws {
    let testArray: [String] = ["a", "b", "c", "d"]
    
    
    let indices: [Int] = testArray.indices.map(\.utf16Offset(in: testArray))
    
    // Sanity check - Indices are normal
    #expect(indices == [0, 1, 2, 3])
    
    // Sanity check - first and last
    #expect(testArray[indices.first!] == "a")
    #expect(testArray[indices.last!] == "d")
    
    // Sanity check - valid indices access expected items
    #expect(testArray[indices[0]] == "a")
    #expect(testArray[indices[1]] == "b")
    #expect(testArray[indices[2]] == "c")
    #expect(testArray[indices[3]] == "d")
    
    #expect(testArray[circular: 4] == "a")
    #expect(testArray[circular: 5] == "b")
    #expect(testArray[circular: 6] == "c")
    #expect(testArray[circular: 7] == "d")
    
  }
}
