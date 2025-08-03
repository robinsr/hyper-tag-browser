// created on 11/11/24 by robinsr

import Factory
import SwiftUI


/**
 Manages the state of a cursor. For cursor-able items displayed
 on a 2D grid, the CursorState moedl also stores a variable jumping
 distance as `verticalDistance`
 */
@Observable
final class CursorState {
  
  typealias Item = ContentItem
    // Using ContentPointer for the selected items set because Set requires Hashable
  //typealias ItemId = ContentPointer
  
  @ObservationIgnored
  private var metrics: AggregatingMeasurement
  
  @ObservationIgnored
  private let logger = EnvContainer.shared.logger("CursorState")
  
  
  init() {
    metrics = Container.shared.metricsRecorder().createHistogram(named: "CursorState")
  }
  
  // Configurable
  var verticalDistance: Int = 2
  var items: [Item] = []
  
  private(set) var position: Int = -1
  private(set) var selectedIds: Set<ContentPointer> = []
  
  var noneSelected: Bool { selectedIds.count == 0 }
  var oneSelected: Bool { selectedIds.count == 1 }
  var anySelected: Bool { selectedIds.count > 0 }
  var manySelected: Bool { selectedIds.count > 1 }
  
  var hoveredItems: Set<ContentIdFocusable> = []
    
  var selection: [Item] {
    items.filter {
      selectedIds.contains($0.pointer)
    }
  }
  
  var transferable: ContentPointers {
    ContentPointers(selectedIds.asArray)
  }
  
  public func clearAndReset() {
    nilCursor()
    clearSelections()
  }
  
  private func itemAllowed(_ item: Item, onPage page: Route.Page) -> Bool {
    if item.diverges(from: .folder) {
      return true
    }
    
    if item.conforms(to: .folder) {
      return page.oneOf(.folder)
    }
    
    return false
  }
  
  public func selectAll() {
    clearSelections()
    
    let targetItems = items
      .filter { itemAllowed($0, onPage: .folder) }
      .collect()
    
    selectedIds = targetItems.pointers.asSet
  }
  
  public func setHoveringTarget(to pointer: ContentPointer, with hoveredType: Any.Type) {
    if hoveredType == FilteringTag.self {
      if contains(pointer) {
          // FilteringTags can be dropped on to multiple items simultaneously using the current selection.
        hoveredItems = selectedIds.map { .receivingTag(on: $0) }.asSet
      } else {
          // If the drop target is not in the selection, the drop action will just apply to that single item
        hoveredItems = [.receivingTag(on: pointer)]
      }
    }
    
    if hoveredType == ContentItem.self {
        // ContentItems can only be dropped onto a single item (e.g. a folder)
      hoveredItems = [.receivingFile(on: pointer)]
    }
  }
  
  public func clearHoveringTarget(of pointer: ContentPointer, with hoveredType: Any.Type) {
    hoveredItems = []
    
//    if hoveredType == ContentItem.self {
//        // ContentItems can only be dropped onto a single item (e.g. a folder)
//      hoveredItems = []
//    }
//    
//    if hoveredType == FilteringTag.self {
//      if contains(target) {
//          // If the removed target is in the selection,
//        hoveredItems = selectedIds.map { .receivingTag(on: $0) }.asSet
//      } else {
//          // If the drop target is not in the selection, the drop action will just apply to that single item
//        hoveredItems = [.receivingTag(on: target.pointer)]
//      }
//    }
  }
  
  
  public func contains(_ itemId: ContentPointer) -> Bool {
    selectedIds.contains(itemId)
  }
  
  public func contains(_ item: Item) -> Bool {
    self.contains(item.pointer)
  }
  
  
  
  public func contains(only item: Item) -> Bool {
    oneSelected && selectedIds.contains(item.pointer)
  }
  
  public func contains(any items: [Item]) -> Bool {
    anySelected && selectedIds.contains(any: items.map { $0.pointer })
  }
  
  public func contains(all items: [Item]) -> Bool {
    anySelected && selectedIds.contains(all: items.map { $0.pointer })
  }
  
  public func positionOf(_ item: Item) -> Int {
    items.firstIndex(where: { $0.id == item.id }) ?? -1
  }
  
  public func positionOf(_ pointer: ContentPointer) -> Int {
    items.firstIndex(where: { $0.id == pointer.contentId }) ?? -1
  }
  
  public func at(_ index: Int) -> Item? {
    items.indices.contains(index) ? items[index] : nil
  }
  
  public func isCursorItem(_ item: Item) -> Bool {
    cursorItem?.id == item.id
  }
  

  public func focusState(of pointer: ContentPointer) -> SelectionItem.State {
    FirstTrueBuilder.withDefault(.none) {
      (hoveredItems.contains(id: pointer.contentId), .hover)
      (self.oneSelected && self.contains(pointer), .active)
      (self.manySelected && self.contains(pointer), .dimmed)
    }
  }
  
  var cursorItem: Item? {
    items.indices.contains(position) ? items[position] : nil
  }
  
  var anyOneSelected: Item? {
    if let firstId = selectedIds.first {
      return items.first(where: { $0.pointer == firstId })
    } else {
      return nil
    }
  }

  private var selectedIndexes: [Int] {
    items.enumerated().compactMap { index, item in
      selectedIds.contains(item.pointer) ? index : nil
    }
  }
  
  private var isContinuous: Bool {
    let indexes = selectedIndexes
    
    let first = indexes.first ?? -1
    let last = indexes.last ?? -1
    let count = indexes.count
    
    return last - first == count - 1
  }
  
  var head: Int {
    items.firstIndex(where: { selectedIds.contains($0.pointer) }) ?? position
  }
  
  var tail: Int {
    items.lastIndex(where: { selectedIds.contains($0.pointer) }) ?? position
  }
  
  enum CursorActions: CustomStringConvertible {
    case selectCurrent(mods: EventModifiers)
    case tap(Item, mods: EventModifiers)
    case leftArrow(mods: EventModifiers)
    case rightArrow(mods: EventModifiers)
    case upArrow(mods: EventModifiers)
    case downArrow(mods: EventModifiers)
    case enterKey(mods: EventModifiers)
    case escape(mods: EventModifiers)
    
    var allowedOn: [Route.Page] {
      switch self {
      case .selectCurrent(_): .browseOnly
      case .tap(_,_): .browseOnly
      case .leftArrow(_): .all
      case .rightArrow(_): .all
      case .upArrow(_): .browseOnly
      case .downArrow(_): .browseOnly
      case .enterKey(_): .browseOnly
      case .escape(_): .all
      }
    }
    
    var id: String {
      switch self {
      case .tap(let item, _): "tap(\(item.id.value))"
      case .selectCurrent(_): "selectCurrent"
      case .leftArrow(_): "leftArrow"
      case .rightArrow(_): "rightArrow"
      case .upArrow(_): "upArrow"
      case .downArrow(_): "downArrow"
      case .enterKey(_): "enterKey"
      case .escape(_): "escape"
      }
    }
    
    var modifiers: EventModifiers {
      switch self {
      case .selectCurrent(let mods),
           .leftArrow(let mods),
           .rightArrow(let mods),
           .upArrow(let mods),
           .downArrow(let mods),
           .enterKey(let mods),
           .escape(let mods):
        return mods
      case .tap(_, let mods):
        return mods
      }
    }
    
    var description: String {
      "CursorState.CursorActions(\(id), mods=\(modifiers.string))"
    }
  }
  
  enum CursorDirection {
    case forward, backward, none
    
    static func forDistance(_ d: Int) -> Self {
      if d == 0 { return .none }
      return d > 0 ? .forward : .backward
    }
  }
  
  @discardableResult
  func dispatch(_ action: CursorActions, from page: Route.Page) -> KeyPress.Result {
    
    guard action.allowedOn.contains(page) else {
      logger.emit(.debug, "Ignoring cursor action \(action.id) on page \(page)")
      
      return .ignored
    }
    
    if case .escape(_) = action {
      if noneSelected {
        logger.emit(.debug, "Nothing selected, Ignoring dismiss action")
        
        // If the cursor is already nil, ignore the escape action
        return .ignored
      }
    }
    
    switch action {
    case .selectCurrent(let mods):
      if let item = cursorItem {
        onTap(item, mods)
      }
    
    case .tap(let item, let mods):
      onTap(item, mods)
    
    case .enterKey(mods: let mods):
      onEnter(mods)
    
    case .escape(_):
      clearSelections()
    
    case .leftArrow(mods: let mods):
      moveBinding(-1, mods, page)
    
    case .rightArrow(mods: let mods):
      moveBinding(1, mods, page)
    
    case .upArrow(mods: let mods):
      moveBinding(-verticalDistance, mods, page)
    
    case .downArrow(mods: let mods):
      moveBinding(verticalDistance, mods, page)
    }
    
    return .handled
  }
  
    /// Resets the cursor to it's initial state, with no selections.
  private func nilCursor() {
    position = -1
  }
  
    /// Moves the cursor to the position of the given item
  private func cursTo(_ item: Item) {
    position = positionOf(item)
  }
  
    /// Adds or removes the given item from the selection set
  private func toggle(_ item: Item) {
    selectedIds.toggleExistence(item.pointer)
  }
  
    /// Removes all items from selection set
  private func clearSelections() {
    selectedIds.removeAll()
  }
  
  /// Replaces all selections with the given item
  private func replace(with item: Item) {
    selectedIds.removeAll()
    selectedIds.insert(item.pointer)
  }
  
   /// Replaces all selections with the given items
  private func replace(with items: [Item]) {
    selectedIds = items.map{ $0.pointer }.asSet
  }
  
    /// Adds the given item to the selection set
  private func add(_ item: Item) {
    selectedIds.insert(item.pointer)
  }
  
  private func onTap(_ item: Item, _ mods: EventModifiers) {
    if contains(only: item) {
      if mods.isPressed(.shift) {
        toggle(item)
        nilCursor()
        return
      }
    }
    
    if noneSelected {
      cursTo(item)
      toggle(item)
      return
    }
    
    if mods.notPressed(.shift) {
      cursTo(item)
      replace(with: item)
      return
    }
    
    if mods.isPressed(.shift) {
      cursTo(item)
      toggle(item)
    }
  }
  
  private func onEnter(_ mods: EventModifiers) {
    // TODO: Uh, should select thing thing that is currently focused
  }
  
  private func moveBinding(_ dist: Int, _ mods: EventModifiers, _ page: Route.Page) {
    if mods.isEmpty { singleMove(distance: dist, page) }
    else if mods.contains(only: .shift) { expandingMove(distance: dist, page) }
  }
  
  private func singleMove(distance moveDistance: Int, _ page: Route.Page) {
    let direction: CursorDirection = .forDistance(moveDistance)
    let currentIndex = direction == .forward ? tail : head
    let nextIndex = items.indices[circular: currentIndex + moveDistance]
    
    guard let item = items[safe: nextIndex] else { return }
    
    if itemAllowed(item, onPage: page) {
      onTap(item, [])
      return
    }
    
    var skipCount = direction == .forward ? 1 : 0
    
    while skipCount < items.count {
      let incIndex = items.indices[circular: currentIndex + moveDistance + skipCount]
      
      guard let item = items[safe: incIndex] else { break }
      
      if itemAllowed(item, onPage: page) {
        onTap(item, [])
        return
      }
      
      if direction == .forward {
        skipCount += 1
      } else {
        skipCount -= 1
      }
    }
  }
  
  private func expandingMove(distance: Int, _ page: Route.Page) {
    let direction: CursorDirection = .forDistance(distance)
    
    if direction == .none { return }
    
    let index = direction == .forward ? tail : head
    let indexN = index + distance
    
    guard let item = items[safe: index] else { return }
    guard let itemN = items[safe: indexN] else { return }
    
    if !isContinuous {
        // Expanding selection of non-continuous items (selected by shift-clicking) not supported
      
      if noneSelected && itemAllowed(item, onPage: page) && itemAllowed(itemN, onPage: page) {
          // But, zero selection is also non-continuous. In that case, select the current
          // cursor item and expand in the direction requested
        
        add(item)
        onTap(itemN, [.shift])
        return
      }
    }
    
    if abs(distance) != 1 {
        // Expanding selection via verticalDistance requires selecting all items
        // between `item` and `itemN`
      
      let lower: Int = min(index, indexN)
      let upper: Int = max(index, indexN)
      
      let interItems = items[lower...upper]
      
      if interItems.allSatisfy({ itemAllowed($0, onPage: page) }) {
        interItems.forEach { add($0) }
        cursTo(itemN)
      }
    } else {
      if itemAllowed(item, onPage: page) {
        onTap(itemN, [.shift])
      }
    }
  }
}


extension CursorState: CustomDebugStringConvertible {
  var debugDescription: String {
    """
    CursorState: {
      position: \(position)
      selectedIds: \(selectedIds.map(\.contentId))
      items: \(items.map{ "\($0.id.value, truncate: 5, from: .front)" })
      itemCount: \(items.count)
      cursorItem: \(cursorItem?.id.value ?? "nil")
    }
    """
  }
}

  //  public func addHovered(_ item: ContentIdFocusable) {
  //    if item.dropType == ContentItem.self {
  //      // ContentItems can only be dropped onto a single item (e.g. a folder), so
  //      // when a .receivingFile type is added, remove all other hovered items
  //      hoveredItems = hoveredItems.filter {
  //        $0.dropType == ContentItem.self
  //      }
  //    }
  //
  //    hoveredItems.toggleExistence(item, shouldExist: true)
  //  }
  //  public func removeHovered(_ item: ContentIdFocusable) {
  //    hoveredItems.toggleExistence(item, shouldExist: false)
  //  }
