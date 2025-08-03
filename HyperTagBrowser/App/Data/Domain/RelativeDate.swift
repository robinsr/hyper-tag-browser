// created on 1/20/25 by robinsr

import Foundation
import GRDB


enum DateBoundary: String, Codable, CaseIterable, CustomStringConvertible {
  case before
  case onOrBefore
  case on
  case onOrAfter
  case after
  
  var isBefore: Bool {
    oneOf(.before, .onOrBefore)
  }
  
  var isAfter: Bool {
    oneOf(.after, .onOrAfter)
  }
  
  var isEquals: Bool {
    oneOf(.on, .onOrBefore, .onOrAfter)
  }
  
  var description: String {
    switch self {
    case .before:
      "before"
    case .onOrBefore:
      "on or before"
    case .on:
      "on"
    case .onOrAfter:
      "on or after"
    case .after:
      "after"
    }
  }
  
  var rawValue: String {
    switch self {
    case .before:
      "<"
    case .onOrBefore:
      "<="
    case .on:
      "=="
    case .onOrAfter:
      ">="
    case .after:
      ">"
    }
  }
}


struct BoundedDate: Codable, CustomStringConvertible, Equatable {
  let date: Date
  let bounds: DateBoundary
  
  var dateFloor: Date {
    date.beginning(of: .day) ?? date
  }
  
  var dateCeil: Date {
    date.end(of: .day) ?? date
  }
  
  var lowerBound: Date {
    switch bounds {
    case .before:
      Date.distantPast
    case .onOrBefore:
      Date.distantPast
    case .on:
      dateFloor
    case .onOrAfter:
      dateFloor
    case .after:
      date.adding(.day, value: 1)
    }
  }
  
  var upperBound: Date {
    switch bounds {
    case .before:
      dateFloor
    case .onOrBefore:
      dateCeil
    case .on:
      dateCeil
    case .onOrAfter:
      Date.distantFuture
    case .after:
      Date.distantFuture
    }
  }
  
  var range: ClosedRange<String> {
    formatted(lowerBound)...formatted(upperBound)
  }
  
  var description: String {
    """
    BoundedDate(
      date: \(formatted(date).quoted),
      bounds: \(bounds.description),
      range: \(formatted(lowerBound).quoted) to \(formatted(upperBound).quoted)
    )
    """
  }
  
  var rawValue: String {
    formatted(date)
  }
  
  private func formatted(_ date: Date) -> String {
    DateFormatter.isoDateTime.string(from: date)
  }
}
