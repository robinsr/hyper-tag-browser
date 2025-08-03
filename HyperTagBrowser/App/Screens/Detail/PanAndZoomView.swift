// created on 9/12/24 by robinsr

import AppKit
import Factory
import SDWebImageSwiftUI
import SwiftUI


struct PanAndZoomView: View {
  private let logger = EnvContainer.shared.logger("PanAndZoomView")
  
  @Environment(\.detailEnv) var detailEnv
  @Environment(\.windowSize) var windowSize
  @Environment(\.enabledFlags) var devFlags
  @Environment(\.currentSheet) var sheet
  
  @State var image: CGImage = .empty
  @State var sendEvents = false
  @State var scrollHandler: Any?
  
  var isEnabled: Bool {
    devFlags.contains(.enable_panAndZoom)
  }
  
  
  let zoomAnimation: Animation = .interactiveSpring()
  let dragAnimation: Animation = .interactiveSpring()
  
  private func handleScrollWheelEvent(_ event: NSEvent) -> NSEvent {
    if event.isExternalMouseDevice() {
      self.handleScrollWheel(event)
    } else if event.isTrackpadDevice() {
      self.handleTrackpadScroll(event)
    }
    
    return event
  }
  
  private func handleScrollWheel(_ event: NSEvent) {
    let value = detailEnv.totalZoom
    let range = detailEnv.minZoom...detailEnv.maxZoom
    let delta = (event.scrollingDeltaY / 1000 / 2).clamped(to: -0.05...0.05)
    let mappedDelta = dampZoomDelta(for: value, in: range, anchor: 1.0, delta: delta, easePower: 3.0)
    
    withAnimation(zoomAnimation) {
      detailEnv.addZoom(value - mappedDelta)
    }
    
    DispatchQueue.main.async {
      detailEnv.acceptZoom()
    }
  }
  
  private func handleTrackpadScroll(_ event: NSEvent) {
    withAnimation(dragAnimation) {
      detailEnv.dragAction = event.scrollDeltaSize
    }
    
    DispatchQueue.main.async {
      detailEnv.acceptDrag()
    }
  }

  var magnifyGesture: some Gesture {
    MagnifyGesture(minimumScaleDelta: 0)
      .onChanged { value in
        withAnimation(zoomAnimation) {
          detailEnv.setZoom(to: value.magnification)
        }
      }
      .onEnded { _ in
        detailEnv.acceptZoom()
      }
  }
  
  var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .local)
      .onChanged { val in
        withAnimation(dragAnimation) {
          detailEnv.dragAction = val.translation
        }
      }
      .onEnded { val in
        withAnimation(dragAnimation) {
          detailEnv.acceptDrag()
        }
      }
  }
  
  func setScrollHandler() {
    self.scrollHandler = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel, handler: handleScrollWheelEvent)
  }
  
  func clearScrollHandler() {
    guard let handler = scrollHandler else { return }
    NSEvent.removeMonitor(handler)
    self.scrollHandler = nil
  }
  
  
  
  var body: some View {
    ZStack(alignment: .center) {
      Group {
        if detailEnv.contentAnimated {
          AnimatedImageContent
        } else {
          ImageContent
        }
      }
      .scaleEffect(isEnabled ? detailEnv.scaleEffect : 1.0)
      .offset(isEnabled ? detailEnv.offsetValue : .zero)
    }
    .background(GeometryReader { geo in
      Color.clear.preference(
        key: ImageSizePreferenceKey.self,
        value: geo.size)
    })
    .modify(when: isEnabled) { $0
      .onPreferenceChange(ImageSizePreferenceKey.self) { pref in
        detailEnv.viewSize = pref
      }
      .gesture(magnifyGesture.simultaneously(with: dragGesture))
//      .onAppear(perform: setScrollHandler)
//      .onDisappear(perform: clearScrollHandler)
//      .onHover { isHovering in
//        isHovering ? setScrollHandler() : clearScrollHandler()
//      }
//      .onChange(of: sheet) {
//        sheet == nil ? setScrollHandler() : clearScrollHandler()
//      }
    }
  }
  
  var ImageContent: some View {
    Image(detailEnv.image, scale: detailEnv.screenScale, label: Text(""))
      .resizable()
      .aspectRatio(contentMode: detailEnv.fillMode)
  }
  
  var AnimatedImageContent: some View {
    WebImage(url: detailEnv.imageContentFileURL)
      .resizable()
      .aspectRatio(contentMode: .fit)
  }
}

struct ImageSizePreferenceKey: PreferenceKey {
  static var defaultValue: CGSize = .zero
  
  static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
    let next = nextValue()
    
    if next != .zero {
      value = next
    }
  }
}
