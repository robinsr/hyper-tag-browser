// created on 11/28/25 by robinsr

import Defaults
import SwiftUI

extension SwiftUI.Binding {
  
  /**
   * Returns a Binding for a UserDefaults value for a specific `Defaults.Key`
   */
  @MainActor
  static func userDefault<T>(_ key: Defaults.Key<T>) -> Binding<T> {
    Binding<T>(
      get: { Defaults[key] },
      set: { val in
        Defaults[key] = val
      }
    )
  }
  
  /**
   * Returns a Binding for a possibly nil UserDefaults value for a specific `Defaults.Key`. Setting
   * the binding to nil will set the userDefaults value to the default value
   */
  @MainActor
  static func userDefault<T>(_ key: Defaults.Key<T>, withDefault defaultValue: T) -> Binding<T?> {
    Binding<T?>(
      get: { Defaults[key] },
      set: { val in
        if let newUrl = val {
          Defaults[key] = newUrl
        } else {
          Defaults[key] = defaultValue
        }
      }
    )
  }
}
