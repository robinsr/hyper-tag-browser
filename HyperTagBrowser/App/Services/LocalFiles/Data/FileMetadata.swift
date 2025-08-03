// created on 1/15/25 by robinsr

import Foundation
import ImageIO
import CustomDump


struct FileMetadata {
  let fileURL: URL
  
  var cgImageSource: CGImageSource? {
    CGImageSourceCreateWithURL(fileURL as CFURL, nil)
  }
  
  var cgImageProperties: [String: Any]? {
    guard let imgSource = cgImageSource else {
      return nil
    }
    
    return CGImageSourceCopyPropertiesAtIndex(imgSource, 0, nil) as? [String: Any]
  }

  var exifData: [String: Any] {
    if let dict = cgImageProperties,
       let exif = dict[exifDict] as? [String: AnyObject] {
      return exif
    } else {
      return [:]
    }
  }
  
  var exifDump: String {
    var propText = ""
    customDump(exifData, to: &propText)
    return propText
  }
  
  var exifComment: String? {
    exifData[commentKey] as? String
  }
  
  private let exifDict = kCGImagePropertyExifDictionary as String
  private let commentKey = kCGImagePropertyExifUserComment as String
}
