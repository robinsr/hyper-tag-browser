// created on 9/26/24 by robinsr

import SwiftUI


struct AlertView: View {
  @Environment(\.messages) var messageQueue
  @Environment(\.dispatcher) var dispatch
  @Environment(\.colorScheme) var colorScheme
  
  let transitionIn: AnyTransition = {
    AnyTransition
      .move(edge: .trailing)
      .animation(.easeInOut(duration: 0.8))
  }()
  
  let transitionOut: AnyTransition = {
    AnyTransition
      .move(edge: .trailing)
      .combined(with: .opacity)
      .animation(.easeInOut(duration: 1.4))
  }()
  
  var toastMessages: [AppMessage] {
    messageQueue.filter(by: \.isTransient)
  }
  
  var sheetMessages: [AppMessage] {
    messageQueue.filter(by: \.isPersistent).first(1).asArray
  }
  
  func isPresented(_ message: AppMessage?) -> Binding<Bool> {
    Binding<Bool>(
      get: { !sheetMessages.isEmpty },
      set: { _ in
        if let msg = message {
          dispatch(.clearMessage(msg))
        }
      }
    )
  }
  
  var body: some View {
    VStack(spacing: 8) {
      ToastList
    }
    .sheetView(isPresented: isPresented(sheetMessages.first), style: AlertViewSheetContent.presentation) {
      if let message = sheetMessages.first {
        AlertViewSheetContent(message: message)
      } else {
        EmptyView()
      }
    }
  }
  
  var ToastList: some View {
    ForEach(toastMessages.reversed(), id: \.id) { message in
      AlertToastView(message: message)
        .id(message.id)
        .transition(.asymmetric(insertion: transitionIn, removal: transitionOut))
    }
  }
}
