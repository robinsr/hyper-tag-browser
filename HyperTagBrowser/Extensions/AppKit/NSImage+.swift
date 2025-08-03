// created on 3/6/25 by robinsr

import AppKit


extension NSImage {
  
  static var empty: NSImage {
    NSImage(size: CGSize(widthHeight: 1), flipped: false) { _ in true }
  }
  
  static var error: NSImage {
    NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: nil)!
  }
  
  /**
  * `UIImage` polyfill.
  */
  convenience init(cgImage: CGImage) {
    self.init(cgImage: cgImage, size: .zero)
  }
  
  func asCGImage() -> CGImage? {
    var rect = NSRect(origin: CGPoint(x: 0, y: 0), size: self.size)
    return self.cgImage(forProposedRect: &rect, context: NSGraphicsContext.current, hints: nil)
  }
  
  
  /**
   * Resize the image to the given size.
   *
   * - Parameter size: The size to resize the image to.
   * - Returns: The resized image.
   */
  func resize(to targetSize: NSSize) -> NSImage {
    let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
    
    let representation = self.bestRepresentation(for: frame, context: nil, hints: nil)
    
    let image = NSImage(
      size: targetSize,
      flipped: false,
      drawingHandler: { (_) -> Bool in
        representation?.draw(in: frame) ?? false
      })

    return image
  }
}
