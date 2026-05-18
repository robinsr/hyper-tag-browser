// created on 5/27/25 by robinsr

import SwiftUI

extension View {
  
  /**
   * Executes an action after a specified time has elapsed without changes to the bound value.
   */
  func onInactivity<T>(
    of value: Binding<T>,
    after timing: DispatchTimeInterval = .milliseconds(100),
    using worker: Binding<DispatchWorkItem?>,
    perform action: @escaping () -> Void
  ) -> some View where T: Equatable {
    self.onChange(of: value.wrappedValue) {
        // Cancel the timeout when the binding's value is changed.
      worker.wrappedValue?.cancel()
      
        // Setup a new timeout to execute the action after the specified delay.
      let newWorkItem = DispatchWorkItem {
        action()
      }
      
        // Store the new work item in the worker binding (requires View to setup a state variable).
      worker.wrappedValue = newWorkItem
      
        // Schedule the new work item to execute after the specified time interval.
      DispatchQueue.main.asyncAfter(.milliseconds(40), execute: newWorkItem)
    }
  }
}
