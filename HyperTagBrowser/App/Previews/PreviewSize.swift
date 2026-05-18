// created on 11/25/25 by robinsr

import SwiftUI


/**
 * Defines sizes for Views rendered with `#Preview`
 */
struct PreviewSize {
  var width: CGFloat
  var height: CGFloat
  
  var cgSize: CGSize {
    CGSize(width: width, height: height)
  }
  
  var taller: Self {
    self.taller(by: 1.7)
  }
  
  func taller(by factor: CGFloat) -> Self {
    PreviewSize(width: width, height: height * factor)
  }
  
  var wider: Self {
    self.wider(by: 1.7)
  }
  
  func wider(by factor: CGFloat) -> Self {
    PreviewSize(width: width * factor, height: height)
  }
  
  func scaled(by factor: CGFloat) -> Self {
    PreviewSize(width: width * factor, height: height * factor)
  }
  
  static func square(_ length: CGFloat, ratio aspectRatio: CGFloat = 1) -> Self {
    // Applies the aspect ratio such that the larger dimensions is no greater than `size`
    let size = CGSize(width: length, height: length).aspectFit(to: length * aspectRatio)
    
    return PreviewSize(width: size.width, height: size.height)
  }
  
  static let superWide: CGFloat = (Constants.smallScreenThreshold * 2) + 20
  
  static let sq200 = PreviewSize.square(200, ratio: 1.0)
  static let sq340 = PreviewSize.square(340, ratio: 1.0)
  static let sq520 = PreviewSize.square(520, ratio: 1.0)
  
  static let wide = PreviewSize.square(260, ratio: 2.5)
  static let xwide = wide.wider(by: 1.5)
  static let wide2xl = wide.wider(by: 2.0)
  static let wide3xl = wide.wider(by: 3.0)
  static let wide4xl = wide.wider(by: 4.0)
  static let wide5xl = wide.wider(by: 5.0)
  
  static let tall = PreviewSize(width: 340, height: 480)
  static let xtall = tall.taller(by: 1.5)
  static let tall2xl = tall.taller(by: 2.0)
  static let tall3xl = tall.taller(by: 3.0)
  static let tall4xl = tall.taller(by: 4.0)
  static let tall5xl = tall.taller(by: 5.0)
  
  static let prefs = PreviewSize.sq340.taller(by: 2.2)
  static let panel = PreviewSize.sq520.taller(by: 0.8)
  static let inspector = PreviewSize.sq340.taller(by: 2.2)
  static let dialog = PreviewSize.sq340.wider(by: 0.75)
}

