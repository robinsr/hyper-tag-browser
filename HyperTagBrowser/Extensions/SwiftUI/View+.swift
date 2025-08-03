// created on 12/20/24 by robinsr

import SwiftUI

extension View {
  
  func hidden(_ shouldHide: Bool) -> some View {
    opacity(shouldHide ? 0 : 1)
      .modify(when: shouldHide) {
        $0.frame(width: 0, height: 0)
      }
  }
  
  func visible(_ shouldShow: Bool) -> some View {
    opacity(shouldShow ? 1 : 0)
      .modify(when: !shouldShow) {
        $0.frame(width: 0, height: 0)
      }
  }

  /**
   * Creates a read-only or one-way binding so that SwiftUI can read
   * the state value, and any attempt to set the value goes to a noop
   */
//  @available(*, deprecated, message: "Use Binding.readOnly instead")
//  func getBinding<T>(_ getter: @escaping () -> (T)) -> Binding<T> {
//    Binding(
//      get: getter,
//      set: { _ in }
//    )
//  }
  
  /**
   * Creates a two-way binding like normal, disposing of the setters value
   * essentially making it a button-esque "onClick" style handler.
   *
   * Usage:
   *
   * ```swift
   * Toggle(isOn: getBinding(
   *   { viewSelected == .list },
   *   { dispatch(.setViewToList) }
   * )) { Text("Show as list") })
   * ```
   */
//  @available(*, deprecated, message: "Use binding.onChange instead")
//  func getBinding<T>(
//    _ getter: @escaping () -> (T),
//    _ setter: @escaping () -> ()
//  ) -> Binding<T> {
//    Binding(get: getter, set: { _ in setter() })
//  }
  
  
  /**
   * Creates a writable binding that evaluates to true when the binding equals value `eq`,
   * and sets the binding equal to `eq` when setting
   *
   * Usage:
   *
   * ```swift
   * Toggle(isOn: getBinding($viewSelected, eq: .grid)) {
   *   Text("Show as grid")
   * }
   * ```
   */
//  @available(*, deprecated, message: "Use Binding.equals(_:) instead")
//  func getBinding<T: Equatable>(_ binding: Binding<T>, eq value: T) -> Binding<Bool> {
//    Binding(get: {
//      binding.wrappedValue == value
//    }, set: { _ in
//      binding.wrappedValue = value
//    })
//  }
  
  
  /**
   * Fills the frame.
  */
  func fillFrame(
    _ axis: Axis.Set = [.horizontal, .vertical],
    alignment: Alignment = .center
  ) -> some View {
    frame(
      maxWidth: axis.contains(.horizontal) ? .infinity : nil,
      maxHeight: axis.contains(.vertical) ? .infinity : nil,
      alignment: alignment
    )
  }
  
  /**
   * Corner radius with a custom corner style.
  */
  func cornerRadius(_ radius: Double, style: RoundedCornerStyle = .continuous) -> some View {
    clipShape(.rect(cornerRadius: radius, style: style))
  }

  /**
   * Draws a border inside the view.
  */
  @_disfavoredOverload
  func border(
    _ shape: some ShapeStyle,
    width lineWidth: Double = 1,
    cornerRadius: Double,
    cornerStyle: RoundedCornerStyle = .circular
  ) -> some View {
    self.cornerRadius(cornerRadius, style: cornerStyle)
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: cornerStyle)
          .strokeBorder(shape, lineWidth: lineWidth)
      }
  }

  /**
   * Draws a border inside the view.
  */
  func border(
    _ color: Color,
    width lineWidth: Double = 1,
    cornerRadius: Double,
    cornerStyle: RoundedCornerStyle = .circular
  ) -> some View {
    self.cornerRadius(cornerRadius, style: cornerStyle)
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius, style: cornerStyle)
          .strokeBorder(color, lineWidth: lineWidth)
      }
  }
  
  
  /**
   * Sets the minimum width and height on the view
   */
  func minimumSize(width: Double, height: Double, alignment: Alignment = .center) -> some View {
    self.frame(minWidth: width, maxWidth: .infinity,
               minHeight: height, maxHeight: .infinity,
               alignment: alignment)
  }
  
  /**
   * Sets the minimum width and height on the view using the dimensions of a `CGSize` instance.
   */
  func minimumSize(_ size: CGSize,alignment: Alignment = .center) -> some View {
    self.minimumSize(width: size.width, height: size.height, alignment: alignment)
  }
  
  
  func selectable() -> some View {
    self.textSelection(.enabled)
  }
}



extension View {
  
  /**
   Applies the `.disabled` modifier when the condition is false.
   */
  @inlinable nonisolated func enabled(_ isEnabled: Bool) -> some View {
    self.disabled(!isEnabled)
  }
}


extension View {
  /**
  Access the native backing-window of a SwiftUI window.
  */
  func accessHostingWindow(_ onWindow: @escaping (NSWindow?) -> Void) -> some View {
    modifier(WindowViewModifier(onWindow: onWindow))
  }

  /**
  Set the window tabbing mode of a SwiftUI window.
  */
  func windowTabbingMode(_ tabbingMode: NSWindow.TabbingMode) -> some View {
    accessHostingWindow {
      $0?.tabbingMode = tabbingMode
    }
  }

  /**
  Set whether the SwiftUI window should be resizable.

  Setting this to false disables the green zoom button on the window.
  */
  func windowIsResizable(_ isResizable: Bool = true) -> some View {
    accessHostingWindow {
      $0?.styleMask.toggleExistence(.resizable, shouldExist: isResizable)
    }
  }

  /**
  Set whether the SwiftUI window should be restorable.
  */
  func windowIsRestorable(_ isRestorable: Bool = true) -> some View {
    accessHostingWindow {
      $0?.isRestorable = isRestorable
    }
  }

  /**
  Make a SwiftUI window draggable by clicking and dragging anywhere in the window.
  */
  func windowIsMovableByWindowBackground(_ isMovableByWindowBackground: Bool = true) -> some View {
    accessHostingWindow {
      $0?.isMovableByWindowBackground = isMovableByWindowBackground
    }
  }

  /**
  Set whether to show the title bar appears transparent.
  */
  func windowTitlebarAppearsTransparent(_ isActive: Bool = true) -> some View {
    accessHostingWindow { window in
      window?.titlebarAppearsTransparent = isActive
    }
  }

  /**
  Set the collection behavior of a SwiftUI window.
  */
  func windowCollectionBehavior(_ collectionBehavior: NSWindow.CollectionBehavior) -> some View {
    accessHostingWindow { window in
      window?.collectionBehavior = collectionBehavior

      // This is needed on windows with `.windowResizability(.contentSize)`. (macOS 13.4)
      // If it's not set, the window will not show in fullscreen mode for some reason.
      DispatchQueue.main.async {
        window?.collectionBehavior = collectionBehavior
      }
    }
  }

  func windowIsVibrant() -> some View {
    accessHostingWindow {
      $0?.makeVibrant()
    }
  }
  
  /**
  Bind the native backing-window of a SwiftUI window to a property.
  */
  func bindHostingWindow(_ window: Binding<NSWindow?>) -> some View {
    background(WindowAccessor(window))
  }
}


private struct WindowViewModifier: ViewModifier {
  @State private var window: NSWindow?

  let onWindow: (NSWindow?) -> Void

  func body(content: Content) -> some View {
    // We're intentionally not using `.onChange` as we need it to execute for every SwiftUI change as the window properties can be changed at any time by SwiftUI.
    onWindow(window)

    return
      content
      .bindHostingWindow($window)
  }
}

private struct WindowAccessor: NSViewRepresentable {
  private final class WindowAccessorView: NSView {
    @Binding var windowBinding: NSWindow?

    init(binding: Binding<NSWindow?>) {
      self._windowBinding = binding
      super.init(frame: .zero)
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
      super.viewWillMove(toWindow: newWindow)

      guard let newWindow else {
        return
      }

      windowBinding = newWindow
    }

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      windowBinding = window
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("")  // swiftlint:disable:this fatal_error_message
    }
  }

  @Binding var window: NSWindow?

  init(_ window: Binding<NSWindow?>) {
    self._window = window
  }

  func makeNSView(context: Context) -> NSView {
    WindowAccessorView(binding: $window)
  }

  func updateNSView(_ nsView: NSView, context: Context) {}
}


extension CustomStringConvertible {
  var asText: some View {
    Text(self.description)
  }
}
