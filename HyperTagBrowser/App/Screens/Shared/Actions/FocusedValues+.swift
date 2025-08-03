// created on 6/8/25 by robinsr

import SwiftUI


struct AppViewModelKey: FocusedValueKey {
  typealias Value = AppViewModel
}

struct ActiveSheetViewKey: FocusedValueKey {
  typealias Value = AppSheet
}

extension FocusedValues {
  var focusedViewModel: AppViewModel? {
    get { self[AppViewModelKey.self] }
    set { self[AppViewModelKey.self] = newValue }
  }
  
  var activeAppSheet: AppSheet? {
    get {
      self[ActiveSheetViewKey.self] ?? AppSheet.none
    }
    set {
      self[ActiveSheetViewKey.self] = newValue
    }
  }
}
