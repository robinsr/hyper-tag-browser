// created on 11/8/24 by robinsr

import SwiftUI
import Defaults


extension View {
  
  @ViewBuilder
  func `if`(_ condition: @autoclosure () -> Bool, modify: (Self) -> some View) -> some View {
    if condition() {
      modify(self)
    } else {
      self
    }
  }

  func `if`(_ condition: @autoclosure () -> Bool, modify: (Self) -> Self) -> Self {
    condition() ? modify(self) : self
  }
  
  @ViewBuilder
  func modify(when condition: @autoclosure () -> Bool, modify: (Self) -> some View) -> some View {
    if condition() {
      modify(self)
    } else {
      self
    }
  }
  
  @ViewBuilder
  func ifLet<T>(_ condition: @autoclosure () -> T?, modify: (Self, T) -> some View) -> some View {
    if let tVal = condition() {
      modify(self, tVal)
    } else {
      self
    }
  }
  
  func modify(when condition: @autoclosure () -> Bool, modify: (Self) -> Self) -> Self {
    condition() ? modify(self) : self
  }
  
  func modify(when source: Binding<Bool>, modify: (Self) -> Self) -> Self {
    source.wrappedValue == true ? modify(self) : self
  }
  
  @ViewBuilder
  func modify(unless condition: @autoclosure () -> Bool, modify: (Self) -> some View) -> some View {
    if condition() {
      self
    } else {
      modify(self)
    }
  }
  
  func modify(unless condition: @autoclosure () -> Bool, modify: (Self) -> Self) -> Self {
    condition() ? self : modify(self)
  }

  @ViewBuilder
  func `if`(
    _ condition: @autoclosure () -> Bool,
    if modifyIf: (Self) -> some View,
    else modifyElse: (Self) -> some View
  ) -> some View {
    if condition() {
      modifyIf(self)
    } else {
      modifyElse(self)
    }
  }

  func `if`(
    _ condition: @autoclosure () -> Bool,
    if modifyIf: (Self) -> Self,
    else modifyElse: (Self) -> Self
  ) -> Self {
    condition() ? modifyIf(self) : modifyElse(self)
  }
}
