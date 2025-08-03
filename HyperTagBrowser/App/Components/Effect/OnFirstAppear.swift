// created on 1/2/25 by robinsr

import SwiftUI


private struct OnFirstAppear: ViewModifier {
  let perform: () -> Void

  @State private var firstTime = true

  func body(content: Content) -> some View {
    content.onAppear {
      if firstTime {
        firstTime = false
        perform()
      }
    }
  }
}

extension View {
  func onFirstAppear(perform: @escaping () -> Void) -> some View {
    modifier(OnFirstAppear(perform: perform))
  }
}
