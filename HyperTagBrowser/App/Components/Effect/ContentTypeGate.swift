// created on 4/18/25 by robinsr

import SwiftUI
import UniformTypeIdentifiers


/**
 A View that renders content only if the `ContentItem` conforms to the specified `UTType`.
 */
struct ContentTypeGate<Content: View>: View {
  
  let item: ContentItem
  let uttype: UTType
  
  @ViewBuilder
  let content: () -> (Content)
  
  var body: some View {
    if item.contentType.conforms(to: uttype) {
      content()
    }
  }
}


struct ContentTypeGateViewModifier: ViewModifier {
  let contentItem: ContentItem
  let contentType: UTType

  func body(content: Content) -> some View {
    ContentTypeGate(item: contentItem, uttype: contentType) {
      content
    }
  }
}

extension View {
  
  /**
   * Modifies the view to only show when `item`'s content type confirms to the specified type
   */
  func when(_ item: ContentItem, conformsTo uti: UTType) -> some View {
    modifier(ContentTypeGateViewModifier(contentItem: item, contentType: uti))
  }
}

