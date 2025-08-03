// created on 3/14/25 by robinsr

import Foundation

extension Comparable {
  
    /// `true` if the value of `other` is greater than self
  func exceeds(_ other: Self) -> Bool {
    self > other
  }

  /// Clamps the value to the specified closed range.
  func clamped(to range: ClosedRange<Self>) -> Self {
    max(range.lowerBound, min(self, range.upperBound))
  }

  /// Clamps the value to the specified range.
  func clamped(to range: Range<Self>) -> Self where Self: BinaryInteger {
    max(range.lowerBound, min(self, range.upperBound - 1))
  }

  /// Clamps the value to the specified partial range.
  func clamped(to range: PartialRangeFrom<Self>) -> Self {
    max(range.lowerBound, self)
  }

  /// Clamps the value to the specified partial range.
  func clamped(to range: PartialRangeUpTo<Self>) -> Self {
    min(range.upperBound, self)
  }

  /// Clamps the value to a minimum value.
  func clamped(min minValue: Self) -> Self {
    max(minValue, self)
  }

  /// Clamps the value to a maximum value.
  func clamped(max maxValue: Self) -> Self {
    min(maxValue, self)
  }

  /// Clamps the value to the specified closed range.
  mutating func clamp(to range: ClosedRange<Self>) {
    self = clamped(to: range)
  }

  /// Clamps the value to specified partial range.
  mutating func clamp(to range: PartialRangeFrom<Self>) {
    self = clamped(to: range)
  }

  /// Clamps the value to specified partial range.
  mutating func clamp(to range: PartialRangeUpTo<Self>) {
    self = clamped(to: range)
  }

  /// Clamps the value to a minimum value.
  mutating func clamp(min minValue: Self) {
    self = clamped(min: minValue)
  }

  /// Clamps the value to a maximum value.
  mutating func clamp(max maxValue: Self) {
    self = clamped(max: maxValue)
  }
}

typealias ComparableAdditive = Numeric & Comparable
