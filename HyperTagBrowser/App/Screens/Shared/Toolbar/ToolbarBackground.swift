// created on 10/20/24 by robinsr

import SwiftUI




struct ToolbarBackgroundViewModifier: ViewModifier {
  @Environment(\.windowSize) var windowSize
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.colorModel) var bgColor
  
  @Binding var useTransparent: Bool

  
  func body(content: Content) -> some View {
    ZStack(alignment: .top) {
      content
        .padding(.top, windowSize.safeArea.top)
      
      ToolbarBackgroundRect
    }
    .edgesIgnoringSafeArea(.all)
    .windowTitlebarAppearsTransparent(true)
    .onChange(of: useTransparent, initial: true) {
      bgColor.update(useTransparent)
    }
  }
  
  var ToolbarBackgroundRect: some View {
    Rectangle()
      .fill(bgColor.secondaryColor)
      .animation(.smooth(duration: 1.0), value: bgColor.secondaryColor)
      .frame(width: windowSize.size.width, height: windowSize.safeArea.top)
      .fillFrame(.horizontal)
      .background {
        if !useTransparent {
          DefaultMaterialBackground
        }
      }
  }
  
  var DefaultMaterialBackground: some View {
    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
      .opacity(bgColor.opacity)
      .transition(.fade(duration: 1.0))
  }
}


extension View {
  
  func withToolbarBackground(useTransparent: Binding<Bool>) -> some View {
    modifier(ToolbarBackgroundViewModifier(useTransparent: useTransparent))
  }
}
