// created on 11/6/25 by robinsr

import Foundation


/**
 * A FIFO queue for ``AppMessage`` messages. Sorts messages by severity. Provides methods for accessing
 * messages by severity level. Keeps queue length within pre-defined constraints.
 */
struct AppMessageQueue {

  var elements: [AppMessage] = []
  var maxCount: Int = 3
  
  var first: AppMessage? {
    elements.first
  }
  
  var last: AppMessage? {
    elements.last
  }
  
  func first(withLevel levels: AppMessage.Level...) -> AppMessage? {
    elements.first { $0.level.oneOf(levels) }
  }
  
  func filter(_ predicate: (AppMessage) -> Bool) -> [AppMessage] {
    elements.filter(predicate)
  }
  
  func filter(withLevel levels: AppMessage.Level...) -> [AppMessage] {
    elements.filter { $0.level.oneOf(levels) }
  }
  
  func filter(by prop: KeyPath<AppMessage, Bool>) -> [AppMessage] {
    elements.filter { $0[keyPath: prop] }
  }
  
  mutating func enqueue(_ message: AppMessage) {
    if message.level.oneOf(.warning, .error) {
      elements.insert(message, at: 0)
    } else {
      elements.append(message)
    }
    
    if elements.count > maxCount {
      elements.removeFirst { $0.isTransient }
    }
  }
  
  mutating func dequeue(_ message: AppMessage) {
    elements = elements.filter {
      $0.id != message.id
    }
  }
  
  mutating func clearMessages(before time: Date) {
    elements = elements
      .filter { $0.isPersistent || $0.newerThan(moment: time) }
      .sorted(by: \.level)
  }
}
