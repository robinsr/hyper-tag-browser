// created on 6/4/25 by robinsr

import AppKit
import SwiftUI

/**
 * A View that displays a keyboard shortcut in a compact box format.
 */
struct KeyBindingHintView: View {
  let binding: KeyBinding

  var body: some View {
    InlineMonospaceTextBox {
      Text(binding.symbols)
        .lineLimit(1)
        .monospacedDigit()
        .tracking(1.8)
        .textScale(.default)
        .bold()
    }
  }
}

/**
 * A View that displays a monospace text box for inline code or other text.
 * This is useful for displaying short snippets of code or commands in a UI.
 */
struct InlineMonospaceTextBox<Content: View>: View {
  @Environment(\.font) var fontScale
  
  @ViewBuilder var content: () -> Content

  @ScaledMetric(relativeTo: .body) var paddingHorizontal = 3.0
  @ScaledMetric(relativeTo: .body) var paddingVertical = 1.0

  var body: some View {
    HStack(spacing: 0) {
      content()
        .monospacedDigit()
    }
    .padding(.horizontal, paddingHorizontal)
    .padding(.vertical, paddingVertical)
    .background {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color.gray.opacity(0.1))
        .stroke(Color.gray.opacity(0.3), lineWidth: 0.4)
    }
  }
}


//#Preview("KeyBindingHintView", traits: .sizeThatFitsLayout, .testBordersOn) {
//  @Previewable @State var bindings: [KeyBinding] = [
//    KeyBinding.help, .dismiss, .openDir, .forward,
//    .goBack, .goForward, .back, .navDirUp, .reload,
//  ]
//  
//  @Previewable @State var sizes: [Font] = [
//    Font.largeTitle, .title, .title2, .title3, .body,
//    .subheadline, .callout, .caption, .caption2, .footnote
//  ]
//
//  VStack(alignment: .leading) {
//    ForEach(Array(zip(bindings, sizes)), id: \.0.id) { kb, fontSize in
//      HStack(spacing: 2) {
//        Text("Lorem ipsum")
//        KeyBindingHintView(binding: kb)
//        Text("dolor sit amet")
//      }
//      .font(fontSize)
//    }
//  }
//  .frame(width: 400, height: 300, alignment: .center)
//}
