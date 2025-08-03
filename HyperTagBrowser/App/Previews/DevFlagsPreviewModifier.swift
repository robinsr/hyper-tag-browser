// created on 5/9/25 by robinsr

import SwiftUI


struct DevFlagsPreviewModifier: PreviewModifier {
  typealias Context = Bool
  
  let flags: [DevFlags]
  
  static func makeSharedContext() async throws -> Context {
    return true
  }
  
  func body(content: Content, context: Context) -> some View {
    content.environment(\.enabledFlags, flags.asSet)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor
  static func devFlags(_ flags: DevFlags...) -> Self {
    self.modifier(DevFlagsPreviewModifier(flags: flags))
  }
}
