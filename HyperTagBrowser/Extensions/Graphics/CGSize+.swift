import Foundation

extension CGSize {
  
  init(_ value: any BinaryInteger) {
    self.init(width: CGFloat(value), height: CGFloat(value))
  }
  
  init(_ value: Double) {
    self.init(width: CGFloat(value), height: CGFloat(value))
  }
  
  static func * (lhs: Self, rhs: Double) -> Self {
    .init(width: lhs.width * rhs, height: lhs.height * rhs)
  }

  init(widthHeight: Double) {
    self.init(width: widthHeight, height: widthHeight)
  }

  var cgRect: CGRect {
    CGRect(origin: .zero, size: self)
  }

  var longestSide: Double {
    max(width, height)
  }

  var shortestSide: Double {
    min(width, height)
  }

  var aspectRatio: Double {
    width / height
  }

  func aspectFit(to boundingSize: CGSize) -> Self {
    let ratio = min(boundingSize.width / width, boundingSize.height / height)
    return self * ratio
  }

  func aspectFit(to widthHeight: Double) -> Self {
    aspectFit(to: Self(width: widthHeight, height: widthHeight))
  }

  func aspectFill(to boundingSize: CGSize) -> Self {
    let ratio = max(boundingSize.width / width, boundingSize.height / height)
    return self * ratio
  }

  func aspectFill(to widthHeight: Double) -> Self {
    aspectFill(to: Self(width: widthHeight, height: widthHeight))
  }

  func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Self {
    Self(width: width.rounded(rule), height: height.rounded(rule))
  }

    /// Example: `140×100`
  var formatted: String {
    "\(Double(width).formatted(.number.grouping(.never)))×\(Double(height).formatted(.number.grouping(.never)))"
  }

  /// Adds the `width` and `height` components of two `CGSize` objects
  func adding(_ other: CGSize) -> CGSize {
    CGSize(width: width + other.width, height: height + other.height)
  }

  /// Computes the relative difference between two CGSize values.
  /// - Parameter other: The other CGSize to compare with.
  /// - Returns: A value representing the relative difference (as a CGFloat).
  func relativeDifference(to other: CGSize) -> CGFloat {
    let widthDifference = abs(self.width - other.width) / max(self.width, other.width)
    let heightDifference = abs(self.height - other.height) / max(self.height, other.height)

    // Return the average relative difference
    return (widthDifference + heightDifference) / 2
  }

  func relativeWidthDifference(to other: CGSize) -> CGFloat {
    abs(self.width - other.width) / max(self.width, other.width)
  }

  func relativeHeightDifference(to other: CGSize) -> CGFloat {
    abs(self.height - other.height) / max(self.height, other.height)
  }
  
  func exceeds(_ other: CGSize) -> Bool {
    width > other.width || height > other.height
  }
  

  func scaled(byFactor factor: CGFloat) -> CGSize {
    CGSize(width: width * factor, height: height * factor)
  }

  func scaled(toFit size: CGSize) -> CGSize {
    var newSize = size
    
    if size.width.oneOf(-1, 0) || size.width == CGFloat.greatestFiniteMagnitude {
      newSize.width = width
    }
    
    if size.height.oneOf(-1, 0) || size.height == CGFloat.greatestFiniteMagnitude {
      newSize.height = height
    }
    
    let ratio = max(width / newSize.width, height / newSize.height)
    
    return CGSize(width: width / ratio, height: height / ratio)
  }

  func scaled(toWidth newWidth: CGFloat) -> CGSize {
    let scale = newWidth / width
    let newHeight = height * scale
    return CGSize(width: newWidth, height: newHeight)
  }

  func scaled(toHeight newHeight: CGFloat) -> CGSize {
    let scale = newHeight / height
    let newWidth = width * scale
    return CGSize(width: newWidth, height: newHeight)
  }

  func scaled(toFill size: CGSize) -> CGSize {
    var newSize = self
    if size.width > size.height {
      newSize = newSize.scaled(toWidth: size.width)
      if newSize.height < size.height {
        newSize = newSize.scaled(toHeight: size.height)
      }
    } else {
      newSize = newSize.scaled(toHeight: size.height)
      if newSize.width < size.width {
        newSize = newSize.scaled(toWidth: size.width)
      }
    }
    return newSize
  }
  
  /**
   * Limits the upper bounds of the resulting CGSize to the specified size.
   */
  func clamped(to size: CGSize) -> CGSize {
    CGSize(
      width: self.width.clamped(to: 0...size.width),
      height: self.height.clamped(to: 0...size.height)
    )
  }

  /**
   * Limits the lower bounds of the resulting CGSize to the specified size.
   */
  func clamped(min size: CGSize) -> CGSize {
    let lowerWidth = min(size.width, self.width)
    let lowerHeight = min(size.height, self.height)
    let upperWidth = max(size.width, self.width)
    let upperHeight = max(size.height, self.height)
    
    return CGSize(
      width: self.width.clamped(to: lowerWidth...upperWidth),
      height: self.height.clamped(to: lowerHeight...upperHeight)
    )
  }
}
