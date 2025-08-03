// created on 2/18/25 by robinsr

import CoreGraphics
import SwiftUI


struct ImageColorSet: Hashable {
  
  let components: [Component]
  
  init(_ elements: [Component]) {
    self.components = elements
  }
  
  init(_ cgColors: [CGColor]) {
    self.components = cgColors.map(Component.init)
  }
  
  var mostSaturated: Color {
    components.sorted(by: \.saturation).first?.asColor ?? Color.clear
  }
  
  var leastSaturated: Color {
    components.sorted(by: \.saturation).last?.asColor ?? Color.clear
  }
  
  var mostLuminous: Color {
    components.sorted(by: \.luminance).first?.asColor ?? Color.clear
  }
  
  var leastLuminous: Color {
    components.sorted(by: \.luminance).last?.asColor ?? Color.clear
  }
  
  static let source = Constants.domColorSource
  
  
  func forScheme(_ scheme: ColorScheme) -> Color {
    // Return the appropriate color based on the color scheme
    switch scheme {
    case .light: self.leastSaturated
    case .dark: self.mostLuminous
    @unknown default:
      self.leastLuminous
    }
  }
  
  struct Component: Hashable {
    let cgColor: CGColor
    let saturation: CGFloat
    let luminance: CGFloat
    
    var asColor: Color {
      Color(cgColor: cgColor)
    }
    
    init(_ color: CGColor) {
      self.init(color, saturation: nil, luminance: nil)
    }
    
    init(_ color: CGColor, saturation: CGFloat?, luminance: CGFloat?) {
      self.cgColor = color
      self.saturation = saturation ?? color.saturation
      self.luminance = luminance ?? color.relativeLuminance
    }
    
    static let nothing: Self = .init(.clear, saturation: 0, luminance: 0)
  }
}


extension ImageColorSet {
  
  static func fromImage(_ cgImage: CGImage) -> ImageColorSet {
    ImageColorSet(cgImage.dominantColors(using: source, count: 6))
  }
  
  static func fromImageData(_ data: Data) -> ImageColorSet {
    .fromImage(ImageDisplay.full.cgImage(from: data) ?? .empty)
  }
  
  static func fromURL(_ url: URL) -> ImageColorSet {
    .fromImage(ImageDisplay.full.cgImage(url: url) ?? .empty)
  }
  
  static let defaults: Self = .init([ImageColorSet.Component.nothing])
}
