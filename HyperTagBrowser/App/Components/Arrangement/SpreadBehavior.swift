// created on 4/4/25 by robinsr

// Why is Angle from SwiftUI and not Spatial?
import SwiftUI



/**
 * Specifies how to spread the rotation angles for a set of items, allowing for different
 * behaviors for a given number of items and maximum angle.
 *
 * This enum defines different strategies for distributing rotation angles across items,
 * such as linear, logarithmic, and dynamic approaches. Each strategy can be used to
 * calculate the rotation angles for a specified number of items and a maximum angle.
 *
 * Members:
 * - `linear`: Distributes angles linearly across items.
 * - `logarithmic`: Distributes angles logarithmically, giving more rotation to earlier items.
 * - `dynamic`: Dynamically adjusts the maximum angle based on the number of items,
 */
enum SpreadBehavior: CustomStringConvertible {
  
    // Applies a linear spread of angles, distributing the rotation evenly across items.
  case linear(maxAngle: Angle)
  
    /// Applies a spread that decreases logarithmically, giving more rotation to earlier items.
  case logarithmic(maxAngle: Angle)
  
    /// Applies a linear spread that varies the `maxAngle` based on `itemCount`, achieving the
    /// maximum angle when `itemCount` reaches `atCount`. The rate at which the max angle is approached
    /// is specified by `approach` (currently either `.linear` or `.logarithmic`)
  case incremental(maxAngle: Angle, atCount: Int, approach: ApproachMethod = .linear)
  
  
    ///
    /// Specifies the method of approaching the maximum angle for dynamic spreads.
    ///
  enum ApproachMethod: String, CaseIterable {
    case linear, logarithmic
  }
  
  
  func rotationMap(itemCount: Int) -> RotationMap {
    switch self {
    case .linear(maxAngle: let maxAngle):
      return SpreadBehavior.linearSpread(n: itemCount, maxO: maxAngle)
    
    case .logarithmic(maxAngle: let maxAngle):
      return SpreadBehavior.logSpread(n: itemCount, maxO: maxAngle)
    
    case .incremental(let maxAngle, let atCount, let approach):
      return SpreadBehavior.incrementalSpread(n: itemCount,
                                              maxO: maxAngle,
                                              reachAt: atCount,
                                              using: approach)
    }
  }
  
  func maxAngle(itemCount: Int) -> Angle {
    switch self {
    case .linear(let maxAngle): maxAngle
    case .logarithmic(let maxAngle): maxAngle
    case .incremental(let maxAngle, _, _): maxAngle
    }
  }
  
  var rawValue: String {
    switch self {
    case .linear(_): "linear"
    case .logarithmic(_): "logarithmic"
    case .incremental(_,_,let approach): "incremental.\(approach.rawValue)"
    }
  }
  
  var description: String {
    switch self {
    case .linear(let maxAngle):
      return "linear(maxAngle: \(maxAngle.degrees)°)"
    case .logarithmic(let maxAngle):
      return "logarithmic(maxAngle: \(maxAngle.degrees)°)"
    case .incremental(let maxAngle, let atCount, let approach):
      return "incremental(maxAngle: \(maxAngle.degrees)°, atCount: \(atCount), approach: \(approach.rawValue))"
    }
  }
}


extension SpreadBehavior {
  
  typealias RotationMap = [Int: Angle]
  
  static var zeroItemsMap: RotationMap { [0: .degrees(0)] }
  
  
    ///
    /// Generates a RotationMap for the `.linear` case.
    ///
  private static func linearSpread(n count: Int, maxO: Angle) -> RotationMap {
    guard count > 0 else { return zeroItemsMap }
    
    return (0..<count).reduce(into: [Int: Angle]()) { dict, index in
      let pos = index
      let base = max(1, count - 1)
      let stepPct = pos.toDouble / base.toDouble
      dict[index] = maxO * stepPct
    }
  }
  
  
    ///
    /// Generates a RotationMap for the `.logarithmic` case.
    ///
  private static func logSpread(n count: Int, maxO: Angle) -> RotationMap {
    (0..<count).reduce(into: [Int: Angle]()) { dict, index in
      let logX = index + 1
      let base = count + 1 // to avoid log(0)
      let stepPct = logX.logC(of: base.toDouble)
      dict[index] = maxO * stepPct
    }
  }
  
    ///
    /// Generates a RotationMap for the `.incremental` case.
    ///
  private static func incrementalSpread(n count: Int, maxO maxAngle: Angle, reachAt: Int, using method: ApproachMethod) -> RotationMap {
    guard count > 1 else { return zeroItemsMap } // Avoid log(1) issues
    
    let adjustedAngle = incrementaAngle(n: count, maxO: maxAngle, cutoff: reachAt, using: method)
    
    switch method {
    case .linear:
      return linearSpread(n: count, maxO: adjustedAngle)
    case .logarithmic:
      return logSpread(n: count, maxO: adjustedAngle)
    }
  }
  
  
    ///
    /// Calculates the `maxAngle` value for `.incremental` cases
    ///
  private static func incrementaAngle(n count: Int, maxO: Angle, cutoff: Int, using method: ApproachMethod) -> Angle {
    guard count > 1 else { return .zero } // Avoid log(1) issues
    guard count < cutoff else { return maxO }
    
    var scale: Double = 0.0
    
    if method == .linear {
      scale = Double(count) / Double(cutoff)
    }
    
    if method == .logarithmic {
      scale = log(Double(count)) / log(Double(cutoff))
    }

    let adjustedMaxAngle = maxO.degrees * scale
    
    return .degrees(adjustedMaxAngle)
  }
}
