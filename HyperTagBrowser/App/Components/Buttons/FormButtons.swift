// created on 12/9/24 by robinsr

import SwiftUI



struct FormButton: View {
  enum ButtonType {
    case confirm, cancel, destructive, primary, secondary, tertiary
    
    var role: ButtonRole? {
      switch self {
      case .cancel: return .cancel
      case .destructive: return .destructive
      default: return nil
      }
    }
  }
  
  var type: ButtonType
  var title: String
  var action: () -> Void
  
  init(_ type: ButtonType, _ title: String, action: @escaping () -> Void) {
    self.type = type
    self.title = title
    self.action = action
  }
  
  var body: some View {
    Button(title, role: type.role ?? .none) {
      action()
    }
    .modify(when: type.oneOf(.confirm, .primary)) {
      $0.buttonStyle(.borderedProminent)
    }
    .modify(when: type.oneOf(.cancel, .secondary, .destructive)) {
      $0.buttonStyle(.bordered)
    }
    .modify(when: type.oneOf(.tertiary)) {
      $0.buttonStyle(.borderless)
    }
    .controlSize(.extraLarge)
    .onKeyPress(.return) {
      action()
      
      return .handled
    }
  }
}


struct FormCancelButton: View {
  var title: String
  var action: () -> Void
  
  init(_ title: String = "Cancel", action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }
  
  var body: some View {
    FormButton(.cancel, title, action: action)
      .focusEffectDisabled()
  }
}


struct FormConfirmButton: View {
  var title: String
  var action: () -> Void
  
  init(_ title: String = "Done", action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }
  
  var body: some View {
    FormButton(.confirm, title, action: action)
      .focusEffectDisabled()
  }
}
