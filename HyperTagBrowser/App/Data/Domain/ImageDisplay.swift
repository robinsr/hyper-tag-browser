// created on 4/12/25 by robinsr

import Combine
import Foundation
import Regex
import SwiftUI
import UniformTypeIdentifiers



/**
 * Represents displayable image sizes.
 *
 * Usage:
 * ```swift
 * ThumbnailDisplay.smallFill.data(for: item.url)
 * ```
 *
 * - `full`: Represents the full-sized image variant.
 * - `small`: Represents a pre-defined small-sized image variant.
 * - `sized`: Represents one-off variable sized thumbnail
 * - `icon`: Represents the icon alternative, typically used for non-image thumbnails
 */
enum ImageDisplay: Hashable {
  case full
  case small(ContentMode)
  case sized(CGSize, ContentMode)
  //case icon
  
  /**
   * Defines the content mode for resizing images.
   *
   * - `fill`: Image is scaled to fill the desired size, producing overflow
   * - `fit`: Image is scaled to fit within the desired size, not overflowing either dimension
   * - `original`: The image will retain its original size.
   * - `squared`: The image will be cropped to a square, centered on the original image.
   *
   * With an input of (300x300), two examples of (100x200) and (200x100):
   *
   *  | ContentMode | 100 x 200 (tall) | 200 x 100 (wide) |
   *  | ----------- | ---------------- | ---------------- |
   *  | `fill`      | 300 x 600        | 600 x 300        |
   *  | `fit`       | 150 x 300        | 300 x 150        |
   *  | `original`  | 100 x 200        | 200 x 100        |
   *  | `squared`   | 300 x 300        | 300 x 300        |
   *
   */
  enum ContentMode: String, CaseIterable {
    case fill, fit, original, squared
    
    var description: String {
      self.rawValue.capitalized
    }
  }
  
  var smallDimensions: CGSize {
    Constants.thumbnailDataSize
  }
  
    
  private func formatImage(_ cgImage: CGImage) -> CGImage? {
    switch self {
    case .full: cgImage
    //case .icon: fatalError("Icon variant not supported for CGImage")
    case .small(let mode):
      switch mode {
      case .original: cgImage.resize(to: smallDimensions)
      case .fit: cgImage.fitting(size: smallDimensions)
      case .fill: cgImage.filling(size: smallDimensions)
      case .squared: cgImage.filling(size: smallDimensions)?.cropCenterSquared()
      }
    case .sized(let size, let mode):
      switch mode {
      case .original: cgImage.resize(to: size)
      case .fit: cgImage.fitting(size: size)
      case .fill: cgImage.filling(size: size)
      case .squared: cgImage.filling(size: size)?.cropCenterSquared()
      }
    }
  }
  
  func cgImage(from data: Data) -> CGImage? {
    guard let image = CGImage.generate(from: data) else {
      return nil
    }
    
    return formatImage(image)
  }
  
  func cgImage(url fileURL: URL) -> CGImage? {
    guard let image = CGImage.generate(for: fileURL) else {
      return nil
    }
    
    return formatImage(image)
  }
  
  func cgImage(for other: CGImage) -> CGImage? {
    formatImage(other)
  }
  
  func pngData(for other: CGImage) -> Data? {
    cgImage(for: other)?.pngData()
  }
  
  func jpegData(for other: CGImage) -> Data? {
    cgImage(for: other)?.jpegData()
  }
  
  func heicData(url other: CGImage) -> Data? {
    cgImage(for: other)?.heicData()
  }
  
  func nsImage(for fileURL: URL) -> NSImage? {
    cgImage(url: fileURL)?.asNSImage
  }
  
  func pngData(url fileURL: URL) -> Data? {
    cgImage(url: fileURL)?.pngData()
  }
  
  func jpegData(url fileURL: URL) -> Data? {
    cgImage(url: fileURL)?.jpegData()
  }
  
  func heicData(url fileURL: URL) -> Data? {
    cgImage(url: fileURL)?.heicData()
  }
}

/**
 * Initially called `ThumbnailDisplay` it found more general use and is now `ImageDisplay`
 */
typealias ThumbnailDisplay = ImageDisplay
