// created on 4/11/25 by robinsr

import Foundation


public extension Sequence {
  
    /// Returns an array of all elements.
  func collect() -> [Element] {
    reduce(into: [Element]()) { $0.append($1) }
  }
  
  func appending(_ element: Element) -> [Element] {
    var result = collect()
    result.append(element)
    return result
  }
  
  func appending<S: Sequence>(_ elements: S) -> [Element] where S.Element == Element {
    var result = collect()
    result.append(contentsOf: elements)
    return result
  }
}

extension Sequence where Element: Identifiable {
  /// Returns an array of the identifiers of the elements in this sequence.
  public var identifiers: [Element.ID] {
    map(\.id)
  }
  
  /// Returns a dictionary mapping the identifiers of the elements to the elements themselves.
  public var idMap: [Element.ID: Element] {
    Dictionary(uniqueKeysWithValues: map { ($0.id, $0) })
  }
}

extension Sequence {
  /// An array of unique elements.
  public func uniqued() -> [Element] where Element: Equatable {
    var elements: [Element] = []
    for element in self {
      if !elements.contains(element) {
        elements.append(element)
      }
    }
    return elements
  }

  /// An array of unique elements in the order they first appear.
  public func uniqued() -> [Element] where Element: Hashable {
    var seen: Set<Element> = []
    return filter { seen.insert($0).inserted }
  }
}

extension Sequence {
  /**
   An array of elements by filtering the keypath for unique values.
  
   - Parameter keyPath: The keypath for filtering the object.
   */
  public func uniqued<T: Equatable>(by keyPath: KeyPath<Element, T>) -> [Element] {
    uniqued(by: { $0[keyPath: keyPath] })
  }

  /**
   An array of elements by filtering the keypath for unique values.
  
   - Parameter keyPath: The keypath for filtering the object.
   */
  public func uniqued<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
    uniqued(by: { $0[keyPath: keyPath] })
  }

  /**
   An array of unique elements.
  
   - Parameter map: A mapping closure. map accepts an element of this sequence as its parameter and returns a value of the same or of a different type.
   */
  public func uniqued<T: Equatable>(by map: (Element) -> T) -> [Element] {
    var uniqueElements: [T] = []
    var ordered: [Element] = []
    for element in self {
      let check = map(element)
      if !uniqueElements.contains(check) {
        uniqueElements.append(check)
        ordered.append(element)
      }
    }
    return ordered
  }

  /**
   An array of unique elements.
  
   - Parameter map: A mapping closure. map accepts an element of this sequence as its parameter and returns a value of the same or of a different type.
   */
  public func uniqued<T: Hashable>(by map: (Element) -> T) -> [Element] {
    var seen = Set<T>()
    return filter { seen.insert(map($0)).inserted }
  }
}

extension Sequence where Element: Hashable {
  /// An array of the elements that are duplicates.
  func duplicates() -> [Element] {
    Array(Dictionary(grouping: self, by: { $0 }).filter { $1.count > 1 }.keys)
  }
}

extension Sequence where Element: Equatable {
  /**
   Returns a random element of the collection excluding any of the specified elements.
  
   - Parameter excluding: The elements excluded for the returned element.
   - Returns: A random element from the collection excluding any of the specified elements. If the collection is empty, the method returns `nil.
   */
  func randomElement<S: Sequence<Element>>(excluding: S) -> Element? {
    filter { !excluding.contains($0) }.randomElement()
  }
  
  func contains<S>(any elements: S) -> Bool where S: Sequence<Element> {
    elements.contains(where: { contains($0) })
  }
  
  func contains<S>(all elements: S) -> Bool where S: Sequence<Element> {
    elements.allSatisfy(AnyIterator(makeIterator()).contains)
  }
}


extension Set {
  var asArray: [Element] {
    Array(self)
  }
}


extension ArraySlice {
  /// Returns an array containing the elements of this slice.
  public var asArray: [Element] {
    Array(self)
  }
}
