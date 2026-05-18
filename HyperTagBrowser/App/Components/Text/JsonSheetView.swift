// created on 12/25/25 by robinsr

import SwiftUI
import GenericJSON
import HighlightSwift


/**
 * Displays a JSON representation of an Encodable object.
 */
struct JsonSheetView: View, SheetPresentable {
  
  static let codeFrame: CGSize = .init(width: 720, height: 440)
  
  static let presentation = SheetPresentation(
    idealSize: Self.codeFrame,
    controls: .close,
    horizontal: [.fixed],
    vertical: [.fixed],
  )
  
  @Binding
  var object: JsonCodeView.JsonEncodable
  
  var onCopy: ((String) -> Void)? = nil
  
  var codeWidth: CGFloat {
    Self.presentation.idealSize.width
  }
  
  var codeHeight: CGFloat {
    Self.presentation.idealSize.height - 45
  }
  
  var contentPadding: EdgeInsets {
    .init(top: 16, leading: 16, bottom: 16, trailing: 12)
  }
  
  var body: some View {
    NavigationStack {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 24) {
          JsonCodeView(object: $object)
            .frame(maxWidth: codeWidth - 24, maxHeight: .infinity, alignment: .leading)
          
          VStack {
            CopyButton
          }
          .modalContentFooter(alignment: .leading)
          .hidden(onCopy == nil)
        }
        .modalContentMain(alignment: .top, padding: contentPadding)
        .frame(minHeight: codeHeight, alignment: .top)
      }
      .scrollIndicators(.visible)
      .navigationTitle("JSON Data")
    }
  }
  
  var CopyButton: some View {
    Button("Copy", .copy) {
      if let copyHandler = onCopy {
        let jsonText = JSONEncoder.pretty(object)
        copyHandler(jsonText)
      }
    }
    .buttonStyle(.bordered)
    .controlSize(.extraLarge)
  }
}

#Preview(
  "JsonSheetView",
  traits: .app, .fixedLayout(width: 720, height: 440), .testBordersOff
) {
  VStack {
    JsonSheetView(
      object: .constant(TestData.testIndexRecords.first(6).asArray),
      onCopy: { txt in
        print("Copied: \(txt, truncate: 50)")
      }
    )
  }
  .preferredColorScheme(.dark)
}
