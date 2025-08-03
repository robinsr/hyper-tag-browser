// created on 5/9/25 by robinsr

import Factory
import SwiftUI


/**
 * Adjusts the size of the preview frame to match the ideal size of the sheet presentation, making
 * previews automatically sized to the typical size of the sheet's intended display size.
 */
struct SheetSizePreviewModifier: PreviewModifier {
  typealias Context = CGSize
  
  @Injected(\.windowObserver) var windowObserver: WindowSizeObserver
  
  let presentation: SheetPresentation
  
  static func makeSharedContext() async throws -> Context { .zero }
  
  func body(content: Content, context: Context) -> some View {
    windowObserver.size = presentation.idealSize
    
    return content
      .frame(width: presentation.idealSize.width, height: presentation.idealSize.height)
      .environment(\.windowSize, windowObserver)
      .environment(\.sheetPresentation, presentation)
      .environment(\.sheetControls, presentation.controls)
      .environment(\.sheetPadding, presentation.padding)
  }
}

extension PreviewTrait where T == Preview.ViewTraits {
  @MainActor
  static func sheetSize(_ sheet: SheetPresentation) -> Self {
    self.modifier(SheetSizePreviewModifier(presentation: sheet))
  }
}
