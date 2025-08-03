// created on 5/9/25 by robinsr

import SwiftUI


struct TestBordersPreviewModifier: PreviewModifier {
  typealias Context = Bool
  
  let enabled: Bool
  
  init(_ enabled: Bool) {
    self.enabled = enabled
  }
  
  static func makeSharedContext() async throws -> Context {
    return true
  }
  
  func body(content: Content, context: Context) -> some View {
    content.environment(\.testBordersEnabled, enabled)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor static var testBordersOn: Self = .modifier(TestBordersPreviewModifier(true))
  @MainActor static var testBordersOff: Self = .modifier(TestBordersPreviewModifier(false))
}
