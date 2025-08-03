// created on 12/6/24 by robinsr

import SwiftUI
import GenericJSON
import HighlightSwift


typealias JSONViewEncodable = any Encodable


/**
 * Displays a JSON representation of an Encodable object.
 */
struct JSONView: View, SheetPresentable {
  static let presentation: SheetPresentation = .code
  
  @Binding var object: JSONViewEncodable

  var json: String {
    JSONEncoder.pretty(object)
  }
  
  var body: some View {
    ScrollView([.vertical, .horizontal]) {
      CodeText(json)
        .codeTextLanguage(.json)
        .multilineTextAlignment(.leading)
        .styleClass(.code)
        .selectable()
        .fixedSize(horizontal: true, vertical: false)
        .frame(
          maxWidth: Self.presentation.expanded.maxWidth,
          maxHeight: Self.presentation.expanded.maxHeight,
          alignment: .top
        )
    }
  }
}

#Preview("JSONView", traits: .defaultViewModel, .defaultLayout, .previewSize(.panel)) {
  @Previewable @State var json: JSON = [
    "key": "value",
    "array": [1, 2, 3],
    "nested": ["key": "value"]
  ]
  
  JSONView(object: .constant(json))
    .padding()
}
