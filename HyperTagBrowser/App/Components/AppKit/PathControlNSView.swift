// created on 1/8/25 by robinsr

import AppKit
import SwiftUI
import CustomDump


struct PathContrlNSView: View, NSViewRepresentable {
  
  @Binding var url: URL
  var onPathClick: (URL) -> Void = { _ in }
  
  var configuration = { (view: NSPathControl) in }
    
  func makeNSView(context: NSViewRepresentableContext<Self>) -> NSPathControl {
    context.coordinator.nsPathView
  }
  
  func updateNSView(_ nsView: NSPathControl, context: NSViewRepresentableContext<Self>) {
    nsView.url = url
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(
      url: url,
      onPathClick: onPathClick
    )
  }

  class Coordinator : NSObject, NSPathControlDelegate {
    let nsPathView = NSPathControl()
    
    let onPathClick: (URL) -> Void
    
    init(url: URL, onPathClick: @escaping (URL) -> Void) {
      self.onPathClick = onPathClick

      super.init()
      
      nsPathView.url = url

      nsPathView.wantsLayer = true
      nsPathView.isEditable = false
      nsPathView.refusesFirstResponder = true
      
      nsPathView.focusRingType = .none
      
      // nsPathView.layer?.cornerRadius = 3.0
      // nsPathView.layer?.borderWidth = 1.0

      nsPathView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
      nsPathView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      
      nsPathView.target = self
      nsPathView.action = #selector(Coordinator.action)
    }
    
    
    @objc func action(sender: NSPathControl) {
      customDump(sender, name: "NSPathControl")
      
      if let url = sender.clickedPathItem?.url {
        onPathClick(url)
      }
    }
  }
}
