// created on 4/18/25 by robinsr

import SwiftUI


@Observable
final class TogglableValue<Value: Equatable> {
  
  let offValue: Value
  let onValue: Value
  
  var currentState: ToggleState = .offState
  
  var currentValue: Value {
    currentState == .onState ? self.onValue : self.offValue
  }
  
  init(offValue: Value, onValue: Value) {
    self.offValue = offValue
    self.onValue = onValue
  }
  
  func toggle() {
    self.currentState = self.currentState.inverted
  }
  
  enum ToggleState {
    case onState, offState
    
    var inverted: ToggleState {
      self == .onState ? .offState : .onState
    }
  }
}
