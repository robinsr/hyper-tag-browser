// created on 4/28/25 by robinsr

extension Array.Indices {
  
  /**
   * Returns a valid index value for any Integer input, looping over the index set
   * such that positive out-of-range values loop back to start, and negative out-of-range
   * values loop from the end
   */
  subscript(circular desiredIndex: Int) -> Int {
    let lastIn = self.last ?? -1
    
    if desiredIndex < 0 {
      let negRemainder = desiredIndex % count
      let fromEnd = count + negRemainder
      return fromEnd
    }
    
    if desiredIndex > lastIn {
      let remainder = desiredIndex % count
      return remainder
    }
    
    return desiredIndex
  }
}
