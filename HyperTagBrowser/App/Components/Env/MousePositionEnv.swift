// created on 10/19/24 by robinsr

import SwiftUI
import Combine

struct MousePositionEnvKey: EnvironmentKey {
  static let defaultValue = MousePositionObserver()
}

extension EnvironmentValues {
  /// An ObservableObject that tracks location of the mouse in the main window
  var mousePosition: MousePositionObserver {
    get { self[MousePositionEnvKey.self] }
    set { self[MousePositionEnvKey.self] = newValue }
  }
}

@Observable
final class MousePositionObserver {
  var coordinates = NSPoint.zero
  var isDragging = false
  var dragType: String? = nil
}

struct MousePositionEnv<Content: View>: View {
  @State var mousePositionState = MousePositionObserver()
  @State var isOverContentView: Bool = false
  
  @ViewBuilder let content: (NSPoint) -> Content
  
  
  var body: some View {
    content(mousePositionState.coordinates)
      .environment(\.mousePosition, mousePositionState)
      .onAppear {
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { evt in
          self.mousePositionState.coordinates = evt.locationInWindow
          
//          let mouseX = self.mousePositionState.coordinates.x
//          let mouseY = self.mousePositionState.coordinates.y
          
//          print("\(isOverContentView ? "Mouse inside ContentView" : "Not inside Content View") x: \(mouseX) y: \(mouseY)")
          
          return evt
        }
      }
  }
}
