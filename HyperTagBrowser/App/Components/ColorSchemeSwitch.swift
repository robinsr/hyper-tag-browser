// created on 4/30/25 by robinsr

import SwiftUI

struct ColorSchemeSwitch<T: Hashable & Sendable>: Sendable {
  typealias Element = T
  
  var lightSchemeValue: T
  var darkSchemeValue: T
  
  init(_ value: T) {
    lightSchemeValue = value
    darkSchemeValue = value
  }
  
  init(_ light: T, _ dark: T) {
    lightSchemeValue = light
    darkSchemeValue = dark
  }
  
  subscript(_ scheme: ColorScheme) -> T {
    switch scheme {
    case .light: return lightSchemeValue
    case .dark: return darkSchemeValue
    @unknown default: return lightSchemeValue
    }
  }
}

extension ColorSchemeSwitch: ExpressibleByArrayLiteral {
  init(arrayLiteral: Element...) {
    guard
      let first = arrayLiteral.first
    else {
      fatalError("ColorSchemeSwitch must be initialized with at least one value")
    }
    
    if let second = arrayLiteral.last {
      self.init(first, second)
    } else {
      self.init(first)
    }
  }
}
