// created on 4/4/25 by robinsr

import Foundation


/**
 * Generates a logarithmic scale of values between a given range.
 *
 * Usage:
 * ```swift
 * let degrees = logarithmicScale(count: 10, range: 0...90)
 * print(degrees)
 * // [0.0, ~21.3, ~33.9, ~43.1, ..., 90.0]
 * ```
 */
func logarithmicScale(count: Int, range: ClosedRange<Double> = 0...1) -> [Double] {
  guard count > 0 else { return [] }
  guard count > 1 else { return [range.lowerBound] }

  let logMax = log(Double(count))

  return (0..<count).map { i in
    let fraction = log(Double(i + 1)) / logMax
    return range.lowerBound + (range.upperBound - range.lowerBound) * fraction
  }
}


/**
 * For `value` in the range `range` to change by amount `delta`, returns a new delta value such that
 * as the value of `value` approaches the lower or upper bound of `range`, the delta value approaches zero.
 */
func dampZoomDelta(
  for value: Double,
  in range: ClosedRange<Double>,
  anchor: Double? = nil,
  delta: Double,
  easePower: Double = 2.0
) -> Double {
  guard range.contains(value) else { return 0 }
  var isTowardsCenter = false
  
  if let anchor = anchor {
    if value.isLess(than: anchor) && delta.isNegative {
      isTowardsCenter = true
    }
    if anchor.isLess(than: value) && delta.isPositive {
      isTowardsCenter = true
    }
  }

  let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
  let proximityFactor = 1.0 - abs(normalized - 0.5) * 2
  let adjustedFactor = pow(proximityFactor, easePower)
  
  if proximityFactor < 0.2 && isTowardsCenter {
    return delta * pow(proximityFactor, easePower / 10)
  }

  return delta * adjustedFactor
}
