// created on 4/12/25 by robinsr

import CoreImage
import Foundation
import UniformTypeIdentifiers


/**
 * A protocol that defines properties required for for generating thumbnails.
 *
 * - `cfURL`: A `CFURL` representing the item's file URL,
 * - `contentType`: A `UTType` representing the item's content type.

 */
protocol ThumbnailableContentItem {
  var fileURL: URL { get }
  var contentType: UTType { get }
}


extension ThumbnailableContentItem {
  
  var pixelWidth: Int {
    Int(pixelDimensions.width)
  }
  
  var pixelHeight: Int {
    Int(pixelDimensions.height)
  }
  
  var pixelDimensions: CGSize {
    guard contentType.conforms(to: .image) else { return .zero }
    
    guard let imgSrc = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
          let props = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, nil) as? [CFString: Any] else {
      return .zero
    }
    
    let width = props[kCGImagePropertyPixelWidth] as! Int
    let height = props[kCGImagePropertyPixelHeight] as! Int
    
    return CGSize(width: CGFloat(width), height: CGFloat(height))
  }
}
