// created on 2/7/25 by robinsr

import AppKit
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import DominantColors
import UniformTypeIdentifiers


extension UTType {
  var cfString: CFString {
    self.identifier as CFString
  }
}


extension CGImage {
  
  static let empty = NSImage.empty.cgImage(forProposedRect: nil, context: nil, hints: nil)!

  var isEmpty: Bool {
    self == CGImage.empty
  }

  /**
   * Initializes a CGImage from a file URL
   */
  static func generate(for imageURL: URL) -> CGImage? {
    let options: [CFString: Any] = [
      kCGImageSourceShouldCache: true,
      kCGImageSourceShouldAllowFloat: true,
    ]
    
    guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, options as CFDictionary) else {
      return nil
    }

    return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
  }

  /**
   * Creates a `CGImage` from a `Data` object
   */
  static func generate(from data: Data) -> CGImage? {
    guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
      return nil
    }

    return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
  }

  /**
   * Creates a `CGImage` from data, using `NSImage` as an intermediary
   */
  static func generate(viaNsImageData data: Data) -> CGImage? {
    guard let nsImage = NSImage(data: data) else {
      return nil
    }

    var rect = NSRect(origin: CGPoint(x: 0, y: 0), size: nsImage.size)

    return nsImage.cgImage(forProposedRect: &rect, context: NSGraphicsContext.current, hints: nil)
  }

  /**
   * Converts current image to NSImage
   */
  var asNSImage: NSImage {
    NSImage(cgImage: self)
  }

  /**
   * Converts the current image to a CIImage
   */
  var asCIImage: CIImage {
    CIImage(cgImage: self)
  }

  static func gaussian(for imageData: Data, radius: Int = 20) -> CIImage? {
    let filter = CIFilter.gaussianBlur()
    filter.setValue(CIImage(data: imageData), forKey: kCIInputImageKey)
    filter.setValue(radius, forKey: kCIInputRadiusKey)
    return filter.outputImage
  }

  // -----------------------------
  // MARK: - Dominant Image Colors
  // -----------------------------

  enum DominantColorSource {
    case kMeans
    case dominantColors
  }

  /**
   * Returns a set of `NSColor` objects representing the dominant colors in this image
   */
  func dominantColors(using source: DominantColorSource, count: Int) -> [CGColor] {
    let options: [DominantColors.Options] = [.excludeBlack, .excludeWhite, .excludeGray]

    func usingKMeans(_ cgImage: CGImage, quality: DominantColorQuality = .fair) throws -> [CGColor]
    {
      try DominantColors.kMeansClusteringColors(
        image: cgImage,
        quality: quality,
        count: count,
        sorting: .frequency)
    }

    func usingDominantColors(_ cgImage: CGImage) throws -> [CGColor] {
      try DominantColors.dominantColors(
        image: cgImage,
        algorithm: .CIE76,
        maxCount: count,
        options: options)
    }

    let fallback: CGColor = .white

    switch source {
      case .kMeans:
        guard let colors = try? usingKMeans(self) else { return [fallback] }
        return colors
      case .dominantColors:
        guard let colors = try? usingDominantColors(self) else { return [fallback] }
        return colors
    }
  }

  // ----------------------
  // MARK: - Image Resizing
  // ----------------------

  /**
   * Returns a `CGSize` of the current images dimensions
   */
  var cgSize: CGSize {
    CGSize(width: width, height: height)
  }

  /**
   * Returns a `CGPoint` representing the current images geometric center
   */
  var centerPoint: CGPoint {
    CGPoint(x: width / 2, y: height / 2)
  }

  func resize(to size: CGSize) -> CGImage? {

    if self.colorSpace == nil {
      print("WARNING!!!! Image color space is nil!")
    }

    // Create a context with the new size
    guard
      let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: self.bitsPerComponent,
        bytesPerRow: 0,          //self.bytesPerRow,
        space: self.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
      )
    else {
      return nil
    }

    // Draw the original image into the new context, scaling it to the new size
    context.interpolationQuality = .high
    context.draw(self, in: CGRect(origin: .zero, size: size))

    // Create and return a new CGImage from the context
    return context.makeImage()
  }

  /**
   * Resizes current image to completly fit in the specified dimensions
   */
  func fitting(size: CGSize) -> CGImage? {
    resize(to: cgSize.scaled(toFit: size))
  }

  /**
   * Resizes current image to fill the specified dimensions. The resulting image exceeds the dimensions in one direction
   */
  func filling(size: CGSize) -> CGImage? {
    resize(to: cgSize.scaled(toFill: size))
  }

  /**
   * Crops the image to the speified size, anchored at the center
   */
  func cropFromCenter(ofSize dimensions: CGSize) -> CGImage? {
    let cropOrigin = CGPoint(
      x: centerPoint.x - (dimensions.width / 2),
      y: centerPoint.y - (dimensions.height / 2)
    )

    let rect = CGRect(origin: cropOrigin, size: dimensions)

    return self.cropping(to: rect)
  }

  /**
   * Crops the image to a square, discarding the the excess width *OR* excess height
   */
  func cropCenterSquared() -> CGImage? {
    let cropSize = CGSize(
      width: min(self.width, self.height),
      height: min(self.width, self.height)
    )

    return cropFromCenter(ofSize: cropSize)
  }

  func jpegData(compressionRatio ratio: CGFloat = 1.0, orientation: Int = 1) -> Data? {
    return autoreleasepool(invoking: { () -> Data in
      let data = NSMutableData()
      let options: NSDictionary = [
        kCGImagePropertyOrientation: orientation,
        kCGImagePropertyHasAlpha: true,
        kCGImageDestinationLossyCompressionQuality: ratio,
      ]

      let imageDestinationRef = CGImageDestinationCreateWithData(
        data as CFMutableData, UTType.jpeg.cfString, 1, nil)!

      CGImageDestinationAddImage(imageDestinationRef, self, options)
      CGImageDestinationFinalize(imageDestinationRef)

      return data as Data
    })
  }
  
  func pngData(orientation: Int = 1) -> Data? {
    return autoreleasepool(invoking: { () -> Data in
      let data = NSMutableData()
      let options: NSDictionary = [
        kCGImagePropertyOrientation: orientation,
        kCGImagePropertyHasAlpha: true,
        kCGImagePropertyPNGComment: "TaggedFileBrowser PNG Image" as NSString,
      ]

      let imgType = UTType.png.identifier as CFString

      let imageDestinationRef = CGImageDestinationCreateWithData(
        data as CFMutableData, UTType.png.cfString, 1, nil)!

      CGImageDestinationAddImage(imageDestinationRef, self, options)
      CGImageDestinationFinalize(imageDestinationRef)

      return data as Data
    })
  }
  
  func heicData(compressionRatio ratio: CGFloat = 1.0, orientation: Int = 1) -> Data? {
    return autoreleasepool(invoking: { () -> Data in
      let data = NSMutableData()
      let options: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: ratio,
        kCGImagePropertyOrientation: orientation,
        kCGImagePropertyHasAlpha: false,
      ]
      
      let destination = CGImageDestinationCreateWithData(
        data as CFMutableData, UTType.heic.cfString, 1, nil)!
      
      CGImageDestinationAddImage(destination, self, options as CFDictionary)
      CGImageDestinationFinalize(destination)
      
      return data as Data
    })
  }
}

extension CGImage: @retroactive Equatable {
  public static func == (lhs: CGImage, rhs: CGImage) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}

/**
 * Extensions for converting to HEIC for optimal storage
 */
extension CGImage {
  var isHeicSupported: Bool {
    (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains("public.heic")
  }
}
