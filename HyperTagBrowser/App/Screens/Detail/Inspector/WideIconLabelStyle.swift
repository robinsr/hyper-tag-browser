// created on 4/30/25 by robinsr

import SwiftUI


struct WideIconLabelStyle: LabelStyle {
  
  enum Variant: String {
    case iconLeading
    case iconTrailing
  }

  var variant: Variant = .iconTrailing
  
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      if variant == .iconLeading {
        configuration.icon
        Spacer()
        configuration.title
      }
      
      if variant == .iconTrailing {
        configuration.title
        Spacer()
        configuration.icon
      }
    }
  }
}

extension LabelStyle where Self == WideIconLabelStyle {
  static var wideTrailingIcon: Self {
    WideIconLabelStyle(variant: .iconTrailing)
  }
  
  static var wideLeadingIcon: Self {
    WideIconLabelStyle(variant: .iconLeading)
  }
}

extension View {
  func iconPlacement(_ variant: WideIconLabelStyle.Variant) -> some View {
    self.labelStyle(WideIconLabelStyle(variant: variant))
  }
}

