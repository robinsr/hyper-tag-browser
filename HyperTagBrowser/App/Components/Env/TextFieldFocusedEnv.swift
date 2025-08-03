// created on 10/26/24 by robinsr

import SwiftUI
import Combine


typealias IsFocused = Binding<Bool>
typealias IsFocusedState = FocusState<Bool>

struct IsTypingEnvKey: EnvironmentKey {
  static let defaultValue: IsFocused = .constant(false)
}

struct TextFieldFocusedEnvKey: EnvironmentKey {
  static let defaultValue = TextFieldFocusedObserver()
}

extension EnvironmentValues {
  
  /**
   * An ObservableObject that tracks when a text field has focus, temporarily preventing keyboard navigation
   */
  var textFieldFocus: TextFieldFocusedObserver {
    get { self[TextFieldFocusedEnvKey.self] }
    set { self[TextFieldFocusedEnvKey.self] = newValue }
  }
  
  /**
   * An Boolean Binding that tracks when a text field has focus, temporarily preventing keyboard navigation
   */
  var isTyping: IsFocused {
    get { self[IsTypingEnvKey.self] }
    set { self[IsTypingEnvKey.self] = newValue }
  }
}

/**
 * An ObservableObject that tracks when a text field has focus, temporarily preventing keyboard navigation
 */
@Observable
final class TextFieldFocusedObserver {
  var focused: Set<String> = []
}

struct TextFieldFocusedEnv<Content: View>: View {
  @ViewBuilder var content: () -> Content
  
  @State var textFocusState = TextFieldFocusedObserver()
  @State var isTyping = false
  
  var body: some View {
    content()
      .environment(\.isTyping, $isTyping)
      .environment(\.textFieldFocus, textFocusState)
      .onChange(of: textFocusState.focused) {
        if textFocusState.focused.isEmpty {
          isTyping = false
        } else {
          isTyping = true
        }
      }
  }
}


struct IsTypingViewModifier : ViewModifier {
  @Environment(\.isTyping) @Binding var isTyping
  
  @FocusState.Binding var focusState: Bool
  
  init(_ focus: FocusState<Bool>.Binding) {
    self._focusState = focus
  }

  func body(content: Content) -> some View {
    content
      .onChange(of: $focusState.wrappedValue) {
        isTyping = $focusState.wrappedValue == true
      }
      .onDisappear {
        isTyping = false
      }
  }
}



extension View {
  func isTyping(_ focus: FocusState<Bool>.Binding) -> some View {
    modifier(IsTypingViewModifier(focus))
  }
}


//struct IsButtonActiveViewModifier : ViewModifier {
//  @Environment(\.isTyping) @Binding var isTyping
//  
//  @Binding var focusState: Bool
//  
//  init(_ focus: Binding<Bool>) {
//    self._focusState = focus
//  }
//
//  func body(content: Content) -> some View {
//    content
//      .onChange(of: $focusState.wrappedValue) {
//        isTyping = $focusState.wrappedValue == true
//      }
//      .onDisappear {
//        isTyping = false
//      }
//  }
//}
//extension View {
//  func activeButton(_ focus: Binding<Bool>) -> some View {
//    modifier(IsButtonActiveViewModifier(focus))
//  }
//}
