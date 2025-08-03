// created on 1/9/25 by robinsr

import AppKit
import Factory
import SwiftUI

struct SearchField: NSViewRepresentable {
  class Coordinator: NSObject, NSSearchFieldDelegate {
    private let logger = EnvContainer.shared.logger("SearchField.Coordinator")
    
    var parent: SearchField
    var nsSearchField: NSSearchField

    init(_ parent: SearchField) {
      self.parent = parent
      
      self.nsSearchField = NSSearchField()
      
      super.init()
      
      self.nsSearchField.delegate = self
      self.nsSearchField.focusRingType = .none
      self.nsSearchField.wantsLayer = true
      
      if let layer = self.nsSearchField.layer {
        // layer.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        layer.backgroundColor = NSColor.darkModeBackgroundColor.withAlphaComponent(0.5).cgColor
        layer.borderColor = .clear
        layer.borderWidth = 1
        layer.cornerRadius = 5
      }
      
      self.nsSearchField.isAutomaticTextCompletionEnabled = true
    }
    
    func controlTextDidChange(_ obj: Notification) {
      if let textField = obj.object as? NSTextField {
        parent.value = textField.stringValue
      }
    }

    func controlTextDidEndEditing(_ obj: Notification) {
      if let textField = obj.object as? NSTextField {
        parent.value = textField.stringValue
      }
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
      if let textField = obj.object as? NSTextField {
        parent.value = textField.stringValue
      }
    }

    func submit() {
      // do something with the text
    }
  }
  
  private let logger = EnvContainer.shared.logger("SearchField")

  @Binding var value: String
  var placeholder: String = "Search"

  func makeNSView(context: NSViewRepresentableContext<SearchField>) -> NSSearchField {
    context.coordinator.nsSearchField
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {
    nsView.stringValue = value
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
}

#Preview("Search Field", traits: .fixedLayout(width: 400, height: 300)) {
  @Previewable @State var query: String = "some search text"

  VStack {
    SearchField(value: $query)
      .preferredColorScheme(.dark)
  }
  .scenePadding()
  
}
