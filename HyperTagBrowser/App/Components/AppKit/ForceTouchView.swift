// created on 6/4/25 by robinsr

import AppKit
import SwiftUI

/**
 * A NSView subclass that supports pressure sensitivity for mouse events.
 */
class PressureSensitiveView: NSView {
  var onPressureChange: ((CGFloat) -> Void)?

  override func pressureChange(with event: NSEvent) {
    super.pressureChange(with: event)
    onPressureChange?(CGFloat(event.pressure))
  }

  override func mouseDown(with event: NSEvent) {
    // Enable pressure sensitivity during mouse press
    window?.trackEvents(
      matching: .pressure,
      timeout: NSEvent.foreverDuration,
      mode: .default
    ) { pressureEvent, stop in
      if let event = pressureEvent {
        self.pressureChange(with: event)
      }
    }
  }

  override var acceptsFirstResponder: Bool { true }
}

// MARK: - SwiftUI wrapper
struct ForceTouchView: NSViewRepresentable {
  var onPressure: (CGFloat) -> Void

  func makeNSView(context: Context) -> PressureSensitiveView {
    let view = PressureSensitiveView()
    view.onPressureChange = onPressure
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.clear.cgColor
    return view
  }

  func updateNSView(_ nsView: PressureSensitiveView, context: Context) {}
}

struct ForceTouchViewModifier: ViewModifier {

  @Binding var isEnabled: Bool
  let onForceTouch: (CGFloat) -> Void
  var onPressureChange: ((CGFloat) -> Void)? = nil

  func body(content: Content) -> some View {
    content
      .background(
        ForceTouchView { pressure in
          // Handle pressure changes here
          if isEnabled {
            onForceTouch(pressure)
          }
        })
  }
}

extension View {
  
  /**
   * Adds a force touch gesture to the view that can detect pressure sensitivity.
   */
  func onForceTouch(
    isEnabled: Binding<Bool>,
    action: @escaping (CGFloat) -> Void,
    onPressureChange: ((CGFloat) -> Void)? = nil
  ) -> some View {
    modifier(
      ForceTouchViewModifier(
        isEnabled: isEnabled,
        onForceTouch: action,
        onPressureChange: onPressureChange
      ))
  }
}
