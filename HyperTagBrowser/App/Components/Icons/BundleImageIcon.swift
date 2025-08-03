// created on 4/2/25 by robinsr

import SwiftUI


struct BundleImageIcon: RawRepresentable, AppIcon {
  var rawValue: String
  var helpText: String? = nil
  var size: CGFloat
  var resource: ImageResource
  var nsImage: NSImage
  
  /* Conforming to `RawRepresentable` */
  init(rawValue: String) {
    self.init(rawValue: rawValue, size: 12)
  }
  
  init(rawValue: String, size: CGFloat) {
    self.rawValue = rawValue
    self.resource = ImageResource(name: rawValue, bundle: .main)
    self.size = size
    self.nsImage = NSImage(resource: resource).resize(to: .init(width: size, height: size))
  }
  
  /// This is a bundle image, so there is no SF Symbol equivalent
  var systemName: String { "questionmark" }
  var id: String { self.rawValue }

  var asImage: Image {
    Image(nsImage: nsImage)
      .renderingMode(.template)
  }
  
  var asIcon: some View {
    Image(nsImage: nsImage)
      .renderingMode(.template)
      .frame(width: size, height: size)
  }
  
  func resized(to size: CGFloat) -> BundleImageIcon {
    BundleImageIcon(rawValue: rawValue, size: size)
  }
  
  static let database = BundleImageIcon(rawValue: "dbimport")
}

