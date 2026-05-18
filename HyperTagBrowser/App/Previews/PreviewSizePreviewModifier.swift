// created on 5/9/25 by robinsr

import Factory
import SwiftUI


/**
 * Adjusts the size of the preview frame to the specified size, and sets the window size observer to match
 * so that any views that depend on the window size can adjust accordingly.
 */
struct PreviewSizePreviewModifier: PreviewModifier {
  typealias Context = CGSize
  
  @Injected(\.windowObserver) var windowObserver: WindowSizeObserver
  
  let size: Context
  
  init(size: Context = CGSize(width: 520, height: 480)) {
    self.size = size
  }
  
  static func makeSharedContext() async throws -> Context {
    CGSize(width: 520, height: 480) // Default size for previews
  }
  
  func body(content: Content, context: Context) -> some View {
    windowObserver.size = CGSize(width: size.width, height: size.height)
    
    print("[PreviewSizePreviewModifier] Applying preview size \(size.formatted)")
    
    return content
      .frame(width: size.width, height: size.height)
      .environment(\.windowSize, windowObserver)
  }
}


extension PreviewTrait where T == Preview.ViewTraits {
  
  @available(*, deprecated, renamed: "size", message: "Use `.size(_:)` instead")
  @MainActor
  static func previewSize(_ size: PreviewSize) -> Self {
    self.modifier(PreviewSizePreviewModifier(size: size.cgSize))
  }
  
  @MainActor
  static func size(_ size: PreviewSize) -> Self {
    self.modifier(PreviewSizePreviewModifier(size: size.cgSize))
  }
}
