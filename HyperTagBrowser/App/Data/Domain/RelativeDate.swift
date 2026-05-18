// created on 1/20/25 by robinsr

import Foundation
import GRDB
import SwiftDate


struct DateFilter: Codable, CustomStringConvertible, Equatable {
  let date: Date
  let comparison: Comparison
  
  static func onDate(_ date: Date) -> Self {
    DateFilter(date: date, comparison: .onDate)
  }
  
  static func before(_ date: Date) -> Self {
    DateFilter(date: date, comparison: .before)
  }
  
  static func after(_ date: Date) -> Self {
    DateFilter(date: date, comparison: .after)
  }
  
  static func onOrBefore(_ date: Date) -> Self {
    DateFilter(date: date, comparison: .onOrBefore)
  }
  
  static func onOrAfter(_ date: Date) -> Self {
    DateFilter(date: date, comparison: .onOrAfter)
  }
  
  static func onDate(_ dateStr: String) -> DateFilter? {
    guard let date = dateStr.toDate("yyyy-MM-dd", region: .local)?.date else { return nil }
    
    return .onDate(date)
  }
  
  static func before(_ dateStr: String) -> DateFilter? {
    guard let date = dateStr.toDate("yyyy-MM-dd", region: .local)?.date else { return nil }
    
    return .before(date)
  }
  
  static func after(_ dateStr: String) -> DateFilter? {
    guard let date = dateStr.toDate("yyyy-MM-dd", region: .local)?.date else { return nil }
    
    return .after(date)
  }
  
  static func onOrBefore(_ dateStr: String) -> DateFilter? {
    guard let date = dateStr.toDate("yyyy-MM-dd", region: .local)?.date else { return nil }
    
    return .onOrBefore(date)
  }
  
  static func onOrAfter(_ dateStr: String) -> DateFilter? {
    guard let date = dateStr.toDate("yyyy-MM-dd", region: .local)?.date else { return nil }
    
    return .onOrAfter(date)
  }
  
  var dateFloor: Date {
    date.beginning(of: .day) ?? date
  }
  
  var dateCeil: Date {
    date.end(of: .day) ?? date
  }
  
  var lowerBound: Date {
    switch comparison {
    case .before: Date.distantPast
    case .onOrBefore: Date.distantPast
    case .onDate: dateFloor
    case .onOrAfter: dateFloor
    case .after: date.adding(.day, value: 1)
    }
  }
  
  var upperBound: Date {
    switch comparison {
    case .before: dateFloor
    case .onOrBefore: dateCeil
    case .onDate: dateCeil
    case .onOrAfter: Date.distantFuture
    case .after: Date.distantFuture
    }
  }
  
  var range: ClosedRange<String> {
    formatted(lowerBound)...formatted(upperBound)
  }
  
  var description: String {
    """
    DateFilter(
      date: \(formatted(date).quoted),
      comparison: \(comparison.description),
      range: \(formatted(lowerBound).quoted) to \(formatted(upperBound).quoted)
    )
    """
  }
  
  var rawValue: String {
    DateFormatter.isoDate.string(from: date)
  }
  
  var displayString: String {
    DateFormatter.medium.string(from: date)
  }
  
  private func formatted(_ date: Date) -> String {
    DateFormatter.isoDateTime.string(from: date)
  }
  
  enum Comparison: String, Codable, CaseIterable, CustomStringConvertible {
    case before
    case onOrBefore
    case onDate
    case onOrAfter
    case after
    
    var isBefore: Bool {
      oneOf(.before, .onOrBefore)
    }
    
    var isAfter: Bool {
      oneOf(.after, .onOrAfter)
    }
    
    var isEquals: Bool {
      oneOf(.onDate, .onOrBefore, .onOrAfter)
    }
    
    var description: String {
      switch self {
      case .before: "before"
      case .onOrBefore: "on or before"
      case .onDate: "on"
      case .onOrAfter: "on or after"
      case .after: "after"
      }
    }
    
    var rawValue: String {
      switch self {
      case .before: "<"
      case .onOrBefore: "<="
      case .onDate: "=="
      case .onOrAfter: ">="
      case .after: ">"
      }
    }
  }

}
