// created on 12/20/24 by robinsr


extension Collection {
  
  /**
   * Works on strings too, since they're just collections.
   **/
  @inlinable
  var nilIfEmpty: Self? {
    isEmpty ? nil : self
  }
  
  
  var notEmpty: Bool {
    !isEmpty
  }
  
  
  /**
   * Returns the element at the specified index if it is within bounds, otherwise `nil`.
   **/
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
  
  /**
   Returns a subsequence containing the first elements.

   - Parameter amount: The number of elements to return.
   */
  public func first(_ amount: Int) -> Self.SubSequence {
      guard !isEmpty, amount > 0 else { return dropFirst(count) }
      return dropLast(count - amount.clamped(max: count))
  }

  /**
   Returns a subsequence containing the last elements.

   - Parameter amount: The number of elements to return.
   */
  public func last(_ amount: Int) -> Self.SubSequence {
      guard !isEmpty, amount > 0 else { return dropFirst(count) }
      return dropFirst(count - amount.clamped(max: count))
  }
}

