// created on 11/12/24 by robinsr

extension Array {
  
  /**
   Returns the element at the given index, wrapping around the array.
   */
  subscript(circular index: Int) -> Int {
    var i = index
    if i < 0 {
      i = count - 1
    } else if i > count - 1 {
      i = 0
    }
    return i
  }
  
  /**
   Identical to `circular` but works on a index range of -1 to `count`.
   */
  subscript(nullable index: Int) -> Int {
    var i = index
    if i < -1 {
      i = count - 1
    } else if i > count {
      i = -1
    }
    return i
  }
  
  /**
   Returns the array's elements as a tuple of index and element.
   */
  var indexed: [(Int, Element)] {
    self.enumerated().map { ($0, $1) }
  }
  
  func isLast(_ item: Element) -> Bool where Element: Equatable {
    guard let lastItem = self.last else {
      return false
    }
    return item == lastItem
  }
}


extension Array where Element: Hashable {
  var asSet: Set<Element> {
    Set(self)
  }
}

extension Collection {
  func indexes(where predicate: (Element) throws -> Bool) rethrows -> [Index] {
    try indices.filter({ try predicate(self[$0]) })
  }
}

extension Collection where Element: Equatable {
  func indexes(of element: Element) -> [Index] {
    indexes(where: { $0 == element })
  }
  
  func indexes<S>(of elements: S) -> [Index] where S: Sequence<Element> {
    indexes(where: { elements.contains($0) })
  }
}

extension RangeReplaceableCollection where Element: Equatable {
  mutating func insert(_ element: Element, before: Element) {
    guard let index = firstIndex(of: before) else { return }
    insert(element, at: index)
  }
  
  mutating func insert(_ element: Element, after: Element) {
    guard let index = firstIndex(of: after) else { return }
    insert(element, at: self.index(after: index))
  }
  
  mutating func replace(_ element: Element, with another: Element) {
    
    for index in indexes(of: element) {
      remove(at: index)
      insert(another, at: index)
    }
  }
}
