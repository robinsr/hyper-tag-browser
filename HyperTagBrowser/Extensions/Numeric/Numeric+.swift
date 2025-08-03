// created on 3/6/25 by robinsr

import Foundation
import RationalModule


extension Double {
  func logC(of base: Double) -> Double {
    return Double.log(self) / Double.log(base)
  }
}

extension Int {
  var hashId: String {
    String(self).base64Encoded ?? String(format: "%20x", self)
  }
}

extension Numeric {
  
    /// Returns the value remaining after subtracting other from value (the difference)
  func remaining(after other: Self) -> Self {
    self - other
  }
  
    /// Returns the value remaining after subtracting other from value (the difference)
  func difference(from other: Self) -> Self {
    self.remaining(after: other)
  }
  
  
  mutating func increment(by value: Self = 1) -> Self {
    self += value
    return self
  }

  mutating func decrement(by value: Self = 1) -> Self {
    self -= value
    return self
  }
}

extension BinaryInteger {
  var toDouble: Double { Double(Int(self)) }
  
  
  func logC(of base: Double) -> Double {
    guard base > 1 else {
      fatalError("Logarithm base must be greater than 1")
    }
    return log(toDouble) / log(base)
  }
}

extension BinaryFloatingPoint {
  
  /// Returns the value formatted as a decimal string with two fractional digits
  /// eg `1234.56789` becomes `"1234.57"`
  var decimalFormat: String {
    self.formatted(FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2)))
  }
}
