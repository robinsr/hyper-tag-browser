// created on 10/22/24 by robinsr

import Factory
import SwiftUI


struct StatusBarViewModifier<InnerContent: View>: ViewModifier {
  
  @Injected(\PreferencesContainer.userPreferences) var userPrefs
  
  @Binding var isPresnted: Bool
  @ViewBuilder let innerContent: () -> (InnerContent)
  
  @State var isHoveringStatusBar = false
//  @State var statusBarHeight: CGFloat = 0
  
  var opacityActive: Double {
    userPrefs.forKey(.statusBarActiveOpacity)
  }
  
  var opacityIdle: Double {
    userPrefs.forKey(.statusBarIdleOpacity)
  }
  
  var barBackground: some ShapeStyle {
    .background.opacity(isHoveringStatusBar ? opacityActive : opacityIdle)
  }
  
  func body(content: Content) -> some View {
    VStack {
      content
        .ignoresSafeArea(.container, edges: .bottom)
        //.padding(.bottom, min(Constants.bodyFontPointSize, statusBarHeight))
    }
    .bottomInset {
      VStack {
        innerContent()
//          .background(GeometryReader { geo in
//            Color.clear.preference(key: StatusBarHeightKey.self, value: geo.size.height)
//          })
      }
      .padding(.vertical, 4)
      .padding(.horizontal, 10)
      .background(barBackground)
      .animation(.easeInOut(duration: 0.2), value: isHoveringStatusBar)
      .onHover { hovering in
        isHoveringStatusBar = hovering
      }
    }
//    .onPreferenceChange(StatusBarHeightKey.self) {
//      statusBarHeight = $0
//    }
  }
}


extension View {
  func statusBar<I: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> I) -> some View {
    modifier(StatusBarViewModifier(isPresnted: isPresented, innerContent: content))
  }
}


struct StatusBarButton<Content: View>: View {
  let action: () -> Void
  let label: () -> Content
  
  var body: some View {
    Button {
      action()
    } label: {
      label()
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}


struct StatusBarHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}
