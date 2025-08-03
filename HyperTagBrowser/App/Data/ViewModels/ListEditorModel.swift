// created on 9/24/24 by robinsr

import SwiftUI
import IdentifiedCollections
import OrderedCollections
import IssueReporting



@Observable
class ListEditorViewModel<T: Hashable> {
  typealias Item = T
  typealias Selectable = SelectableItem<T>
  
  var elements: [Selectable] = []
  var head: Selectable.ID?
  var tail: Selectable.ID?
  
  
  init(_ initial: [Selectable]) {
    elements.append(contentsOf: initial)
  }
  
  init(_ initial: [Item]) {
    elements.append(contentsOf: initial.map {
      Selectable(item: $0)
    })
  }
  
  private func replaceContents(of target: Selectable, with contents: Item) -> Selectable {
    Selectable(id: target.id, selected: target.selected, item: contents)
  }
  
  private func toggleItem(of target: Selectable, with contents: Item) -> Selectable {
    Selectable(id: target.id, selected: !target.selected, item: contents)
  }
  
  private func newSelection(using item: Item) -> Selectable {
    Selectable(item: item)
  }
  
  private func dedupeItem(_ item: Item) -> Selectable? {
    var seen: Set<Item> = elements.map(\.item).asSet
    
    if seen.insert(item).inserted {
      return newSelection(using: item)
    } else {
      return nil
    }
  }
  
  private func dedupeItems(_ items: [Item]) -> [Selectable] {
    var seen: Set<Item> = elements.map(\.item).asSet
    
    return items
      .filter { seen.insert($0).inserted }
      .map { newSelection(using: $0) }
  }
  
  func setHead(to id: Selectable.ID) {
    unimplemented("SequentialList#setHead not implemented")
  }
  
  func setTail(to id: Selectable.ID) {
    unimplemented("SequentialList#setTail not implemented")
  }
  
  var first: Selectable? {
    return elements.first
  }
  
  var last: Selectable? {
    return elements.last
  }
  
  var endIndex: Int {
    return elements.endIndex
  }
  
  var startIndex: Int {
    return elements.startIndex
  }
  
  func insert(_ newT: Item, at position: Int) {
    if let newItem = dedupeItem(newT) {
      elements.insert(newItem, at: position)
    }
  }
  
  func insert(_ newT: Item, before member: Selectable?) {
    guard let member else { return }
    
    if let position = elements.firstIndex(of: member), let newItem = dedupeItem(newT) {
      elements.insert(newItem, at: max(elements.startIndex, position))
    }
  }
  
  func insert(_ newT: Item, after member: Selectable?) {
    guard let member else { return }
    
    if let position = elements.firstIndex(of: member), let newItem = dedupeItem(newT) {
      elements.insert(newItem, at: position + 1)
    }
  }
  
  func insert(_ newT: Item, beforeId id: Selectable.ID?) {
    guard let id else { return }
    
    if let member = retrieveBy(id: id), let newItem = dedupeItem(newT) {
      elements.insert(newItem, before: member)
    }
  }
  
  func insert(_ newT: Item, afterId id: Selectable.ID?) {
    guard let id else { return }
    
    if let member = retrieveBy(id: id), let newItem = dedupeItem(newT) {
      elements.insert(newItem, after: member)
    }
  }
  
  func append(_ newT: Item) {
    if let newItem = dedupeItem(newT) {
      elements.insert(newItem, at: elements.endIndex)
    }
  }
  
  func append(contentsOf items: [Item]) {
    elements.append(contentsOf: dedupeItems(items))
  }
  
  func prepend(_ newT: Item) {
    if let newItem = dedupeItem(newT) {
      elements.insert(newItem, at: elements.startIndex)
    }
  }
  
  func replace(_ all: [Item]) {
    self.elements.removeAll()
    self.elements.append(contentsOf: dedupeItems(all))
  }
  
  func replace(_ target: Selectable, with newT: Item) {
    if let newItem = dedupeItem(newT) {
      elements.replace(target, with: newItem)
    }
  }
  
  func replace(id: Selectable.ID?, with newT: Item) {
    guard let id else { return }
    
    if let target = retrieveBy(id: id), let newItem = dedupeItem(newT) {
      elements.replace(target, with: newItem)
    }
  }
  
  func update(id: Selectable.ID, with newT: T) {
    if let target = retrieveBy(id: id) {
      elements.replace(target, with: replaceContents(of: target, with: newT))
    }
  }
  
  func toggle(id: Selectable.ID) {
    if let target = retrieveBy(id: id) {
      elements.replace(target, with: toggleItem(of: target, with: target.item))
    }
  }
  
  func contains(_ sel: Selectable) -> Bool {
    elements.contains(sel)
  }
  
  func contains(item: Item) -> Bool {
    elements.contains(where: { $0.item == item })
  }
  
  func indexOf(_ sel: Selectable?) -> Int? {
    guard let sel else {
      return nil
    }
    
    return elements.firstIndex { $0.id == sel.id }
  }
  
  func indexOf(id: Selectable.ID?) -> Int? {
    guard let id else {
      return nil
    }
    
    return elements.firstIndex { $0.id == id }
  }
  
  func retrieveBy(id: Selectable.ID) -> Selectable? {
    elements.first { $0.id == id }
  }
  
  func retrieveBy(index: Int) -> Selectable? {
    return elements.indices.contains(index) ? elements[index] : nil
  }
  
  func next(afterId itemId: Selectable.ID) -> Selectable? {
    if let index = indexOf(id: itemId) {
      let nextIndex = index + 1
      
      if nextIndex < elements.endIndex {
        return elements[nextIndex]
      }
    }
    
    return elements.first
  }
  
  func previous(beforeId itemId: Selectable.ID) -> Selectable? {
    if let index = indexOf(id: itemId) {
      let nextIndex = index - 1
      
      if elements.indices.contains(nextIndex) {
        return elements[nextIndex]
      }
    }
    
    return elements.last
  }
  
  func isFirst(id itemId: Selectable.ID) -> Bool {
    guard let firstItem = elements.first else {
      return false
    }
    
    return firstItem.id == itemId
  }
  
  func isLast(id itemId: Selectable.ID) -> Bool {
    guard let lastItem = elements.last else {
      return false
    }
    
    return lastItem.id == itemId
  }
}
