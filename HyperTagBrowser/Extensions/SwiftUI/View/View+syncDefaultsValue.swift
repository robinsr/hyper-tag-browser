// created on 5/27/25 by robinsr

import Defaults
import SwiftUI


extension View {
  
  /**
   * Syncs a `Defaults.Key` value with a SwiftUI `Binding`
   *
   * This method sets up two-way synchronization between a `Defaults.Key` and a SwiftUI `Binding`.
   *
   * - Parameters:
   *  - key: The `Defaults.Key` to sync when the binding's value changes
   *  - state: The `Binding` to sync when the `Defaults.Key` changes
   *  - initial: Whether a sync should be run when this view initially appears.
   */
  func syncDefaultsValue<T>(
    _ key: Defaults.Key<T>,
    with state: Binding<T>,
    initial: Bool = false
  ) -> some View where T: Equatable {
    self
      .onAppear {
        guard initial else { return }
        state.wrappedValue = Defaults[key]
      }
      .onChange(of: state.wrappedValue, debounceTime: .milliseconds(30)) {
        let stateVal = state.wrappedValue
        let keyedVal = Defaults[key]
        
        if stateVal != keyedVal {
          Defaults[key] = stateVal
        }
      }
      .onChange(of: Defaults[key], debounceTime: .milliseconds(30)) {
        let stateVal = state.wrappedValue
        let keyedVal = Defaults[key]
        
        if stateVal != keyedVal {
          state.wrappedValue = keyedVal
        }
      }
  }
}

