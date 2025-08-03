// created on 3/31/25 by robinsr

import SwiftUI


/**
 * A gesture that calls the `onResize` closure with the width of the drag gesture's
 * translation. Useful for resizing views horizontally.
 *
 * Example:
 * ```swift
 * struct ContentView: View {
 *  @State private var width: CGFloat = 200
 *
 *  var body: some View {
 *    Rectangle()
 *      .frame(width: width, height: 200)
 *      .gesture(HorizontalResizeGesture { delta in
 *        width += delta
 *      })
 *    }
 *  }
 *  ```
 */
struct HorizontalResizeGesture: Gesture {
  var onResize: (Double) -> Void
  
  var body: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .local)
      .onChanged { value in
        onResize(Double(value.translation.width))
      }
      .onEnded { value in
        onResize(0)
      }
  }
}

extension View {
  
  /**
    * Adds a horizontal resize gesture to the view that calls the `onResize` closure with the
    * width of the drag gesture's translation.
   */
  func horizontalResizeGesture(
    isEnabled enabled: Bool = true,
    onResize: @escaping (Double) -> Void
  ) -> some View {
    self.gesture(
      HorizontalResizeGesture(onResize: onResize),
      isEnabled: enabled)
  }
}
