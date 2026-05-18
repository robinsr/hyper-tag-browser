// created on 12/6/24 by robinsr

import SwiftUI
import HighlightSwift


/**
 * Displays a JSON representation of an Encodable object.
 */
struct JsonCodeView: View {
  
  typealias JsonEncodable = any Encodable
  
  @Binding
  var object: JsonEncodable

  var jsonText: String {
    JSONEncoder.pretty(object)
  }
  
  var body: some View {
    CodeText(jsonText)
      .codeTextLanguage(.json)
      .multilineTextAlignment(.leading)
      .styleClass(.code)
      .selectable()
  }
}


#Preview(
  "JsonCodeView",
  traits: .app, .fixedLayout(width: 720, height: 440), .testBordersOff
) {
  VStack {
    JsonCodeView(
      object: .constant(TestData.testIndexRecords.first(6).asArray)
    )
  }
  .preferredColorScheme(.dark)
}
