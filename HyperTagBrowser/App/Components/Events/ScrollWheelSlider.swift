// created on 10/23/24 by robinsr

import SwiftUI
import Foundation

struct ScrollWheelSlider<Content: View>: View {
  var name: String
  @Binding var value: Double
  var minValue: Double
  var maxValue: Double
  var step: Double = 0.1
  let minLabel: Content
  let maxLabel: Content

  /// If true, the slider will respond to scroll wheel events.
  /// Disable this if scroll events are monitored elsewhere.
  /// Without it its just a basic Slider, so maybe just use that.
  var useScrollEvents: Bool = false
  
  func onScrollEvent(event: NSEvent) -> NSEvent {
    if event.subtype != .mouseEvent {
      /// Ignore trackpad events. Trackpad zoom should be
      /// implemented as magnify gesture
      return event
    }
    
    let delta = event.scrollingDeltaY
    
    if (delta > 0) {
      /// Positive delta. Update value up to maxValue
      value = Double.minimum(value + step, maxValue)
    }
    if (delta < 0) {
      /// Negative delta. Update value down to minValue
      value = Double.maximum(value - step, minValue)
    }
    
    return event
  }
  
  var body: some View {
    var scrollMonitor: Any?
    
    Slider(
      value: $value,
      in: minValue...maxValue,
      minimumValueLabel: minLabel,
      maximumValueLabel: maxLabel
    ) {
     Text(name)
    }
    .frame(width: 125)
    .onAppear {
      if useScrollEvents {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel, handler: onScrollEvent)
      }
    }
    .onDisappear {
      if scrollMonitor != nil {
        NSEvent.removeMonitor(scrollMonitor!)
      }
    }
  }
}
