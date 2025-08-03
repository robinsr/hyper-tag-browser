// created on 3/6/25 by robinsr


extension SetAlgebra {

  /**
   * Insert the `value` if it doesn't exist, otherwise remove it.
   */
  mutating func toggleExistence(_ value: Element) {
    if contains(value) {
      remove(value)
    } else {
      insert(value)
    }
  }

  /**
   * Insert the `value` if `shouldExist` is true, otherwise remove it.
   **/
  mutating func toggleExistence(_ value: Element, shouldExist: Bool) {
    if shouldExist {
      insert(value)
    } else {
      remove(value)
    }
  }
}
