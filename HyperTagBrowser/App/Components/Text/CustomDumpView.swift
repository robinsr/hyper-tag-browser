// created on 12/6/24 by robinsr

import SwiftUI
import CustomDump
import HighlightSwift


struct CustomDumpView: View {
  
  var text: String = ""
  var onCopy: ((String) -> Void)? = nil
  
  init(_ value: AnyObject, _ label: String = "", onCopy: ((String) -> Void)? = nil) {
    self.onCopy = onCopy
    customDump(value, to: &text, name: label)
  }
  
  init(_ value: Any, _ label: String = "", onCopy: ((String) -> Void)? = nil) {
    self.onCopy = onCopy
    customDump(value, to: &text, name: label)
  }
  
  var body: some View {
    VStack {
      ScrollView {
        CodeText(text)
          .codeTextLanguage(.swift)
          .fixedSize(horizontal: false, vertical: true)
          .styleClass(.code)
          .selectable()
      }
      .scrollIndicators(.never)
      
      FullWidth(alignment: .trailing) {
        Button("Copy") {
          onCopy?(text)
        }
        .buttonStyle(.bordered)
      }
      .hidden(onCopy == nil)
    }
  }
}
