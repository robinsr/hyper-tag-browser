// Created by robisnr on 2024-09-15

import Factory
import SwiftUI


/**
 * Adds a WindowSizeObserver to the environment, and updates the observer with the current window size
 */
struct WindowSizeEnvironmentView: ViewModifier {
  // @Injected(\.windowObserver) var model: WindowSizeObserver
  @Environment(\.windowSize) var model: WindowSizeObserver
  
  func body(content: Content) -> some View {
    GeometryReader { geometry in
      content
        //.environment(\.windowSize, model)
        .onChange(of: geometry.size.width, initial: true) { newWidth, _ in
          
          let frameSize = geometry.frame(in: .local)
          
          model.size = frameSize.size
          model.safeArea = geometry.safeAreaInsets
        }
    }
  }
}

extension View {
  func withWindowSizeEnvironment() -> some View {
    modifier(WindowSizeEnvironmentView())
  }
}

extension EnvironmentValues {
    /// An ObservableObject that tracks the main window's dimensions
  @Entry var windowSize = Container.shared.windowObserver()
}
