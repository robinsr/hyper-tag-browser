// created on 4/23/25 by robinsr

import SwiftUI
import UniformTypeIdentifiers


struct ObscureContentsViewModifier: ViewModifier {
  @Binding var isHidden: Bool
  
  @Environment(\.releventContentType) var contentType: UTType?
  @Environment(\.enabledFlags) var enabledFlags
  
  var contentTypeException: Bool {
      // Not applied to folder types
    contentType?.conforms(to: .folder) ?? false
  }
  
  var flagEnabled: Bool {
    enabledFlags.contains(.enable_obscureContent)
  }
  
  var obscured: Bool {
    !contentTypeException && (isHidden || flagEnabled)
  }
  
  func body(content: Content) -> some View {
    content
      .blur(radius: obscured ? 15 : 0)
      .clipped()
      .modify(when: obscured) {
        $0.overlay(BlurShape)
      }
  }
  
  var BlurShape: some View {
    VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
      .clipShape(Rectangle())
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .opacity(0.3)
      //.opacity(0.0)
  }
}

extension View {
  func obscureContents(enabled isHidden: Binding<Bool>) -> some View {
    modifier(ObscureContentsViewModifier(isHidden: isHidden))
  }
}

