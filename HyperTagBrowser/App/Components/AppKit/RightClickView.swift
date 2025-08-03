// created on 1/22/25 by robinsr

import SwiftUI
#if os(macOS)
import AppKit
#endif


final class ClickableViewConfiguration: ObservableObject {
  enum ClickType {
    case left
    case right
    case other
  }
  
  struct ClickHandler {
    var type: ClickType
    var function: () -> Void
  }
  
  init(handlers: [ClickHandler]) {
    self.handlers = handlers
  }
  
  var handlers: [ClickHandler]
}


#if os(macOS)
struct AnyClickableSwiftUIView: NSViewRepresentable {
  
  @Binding var clickState: ClickableViewConfiguration.ClickType?
  
  func updateNSView(_ nsView: AnyClickableNSView, context: NSViewRepresentableContext<AnyClickableSwiftUIView>) {}
  
  func makeNSView(context: Context) -> AnyClickableNSView {
    AnyClickableNSView(clickState: $clickState)
  }
}

class AnyClickableNSView: NSView {

  @Binding var clickState: ClickableViewConfiguration.ClickType?
    
  required init?(coder: NSCoder) {
    fatalError()
  }
    
  init(clickState: Binding<ClickableViewConfiguration.ClickType?>) {
    self._clickState = clickState
    super.init(frame: NSRect())
  }

  override func mouseDown(with theEvent: NSEvent) {
    clickState = .left
  }
    
  override func rightMouseDown(with theEvent: NSEvent) {
    clickState = .right
  }
  
  override func otherMouseDown(with theEvent: NSEvent) {
    clickState = .other
  }
}
#endif

struct AnyClickableViewModifier: ViewModifier {
  
  let onClick: (ClickableViewConfiguration.ClickType) -> Void
  
  @State var clickState: ClickableViewConfiguration.ClickType? = nil
  
  func body(content: Content) -> some View {
    content
    #if os(macOS)
      .overlay {
        AnyClickableSwiftUIView(clickState: $clickState)
          .onChange(of: clickState) {
            guard let clickState = clickState else { return }
            onClick(clickState)
            
            DispatchQueue.main.async {
              self.clickState = nil
            }
          }
      }
    #endif
  }
}


typealias ClickMap = [ClickableViewConfiguration.ClickType: () -> Void]

extension View {
  func clickable(onClick: @escaping (ClickableViewConfiguration.ClickType) -> Void) -> some View {
    modifier(AnyClickableViewModifier(onClick: onClick))
  }
}
