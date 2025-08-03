// created on 5/9/25 by robinsr

import SwiftUI

struct DetailScreenModelPreviewMod: PreviewModifier {
  typealias Context = DetailScreenViewModel
  
  static func makeSharedContext() async -> Context {
    return DetailScreenViewModel()
  }
  
  func body(content: Content, context: Context) -> some View {
    content
      .environment(\.detailEnv, context)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor
  static var detailScreen: Self {
    self.modifier(DetailScreenModelPreviewMod())
  }
}
