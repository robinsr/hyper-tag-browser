// created on 4/12/25 by robinsr

import CoreImage
import Foundation


extension Data {
  func asCGImage() -> CGImage? {
    guard let imageSource = CGImageSourceCreateWithData(self as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
      return nil
    }
    return cgImage
  }
}
