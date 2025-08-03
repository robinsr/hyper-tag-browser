// created on 4/2/25 by robinsr

import SwiftUI

extension Label where Image == Icon, Title == Text {
  /**
   Initializes a `Label` view using a `helpText` and `systemName` from a ``SymbolIcon``
   */
  init(_ symbol: SymbolIcon) {
    self.init(symbol.helpText ?? "", systemImage: symbol.systemName)
  }
  
  /**
   Initializes a `Label` view using the provided `title` and `systemName` from a ``SymbolIcon``
   */
  init(_ title: String, _ symbol: SymbolIcon) {
    self.init(title, systemImage: symbol.systemName)
  }
  
  /**
   Initializes a `Label` view using a `helpText` and `systemName` from a ``BundleImageIcon``
   */
  init(_ bundleIcon: BundleImageIcon) {
    self.init {
      Text(bundleIcon.helpText ?? "")
    } icon: {
      bundleIcon.asImage
    }
  }
  
  /**
   Initializes a `Label` view using the provided `title` and `systemName` from a ``BundleImageIcon``
   */
  init(_ title: String, _ bundleIcon: BundleImageIcon) {
    self.init {
      Text(title)
    } icon: {
      bundleIcon.asImage
    }
  }
}


// TODO: applies 16x16 frame on image used as label's icon
extension Label where Image == Icon, Title == Text {
  init(_ title: String, _ image: Image) {
    self.init {
      Text(title)
    } icon: {
      image
    }
  }
}
