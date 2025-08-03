// created on 1/3/25 by robinsr

import SwiftUI


enum ExternalApp {
  case finder, systemDefault
}


extension Button where Label == SwiftUI.Text {
  init(_ fileURL: URL, using app: ExternalApp = .finder, @ViewBuilder label: () -> Label) {
    self.init(action: {
      switch app {
      case .finder:
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
      case .systemDefault:
        NSWorkspace.shared.open(fileURL)
      }
    }, label: {
      label()
    })
  }
}


struct ShowInFinderButton: View {
  var title: String = "Show in Finder"
  let fileURL: URL
  
  var body: some View {
    OpenExternalAppButton(fileURL: fileURL)	{
      Text(title)
    }
  }
}


struct OpenExternalAppButton: View {
  var fileURL: URL
  var app: ExternalApp
  var label: Text
  
  init(fileURL: URL,
       using app: ExternalApp = .finder,
       @ViewBuilder label: @escaping () -> (Text) = { Text("Show in Finder") }) {
    self.fileURL = fileURL
    self.app = app
    self.label = label()
  }
  
  var body: some View {
    Button(fileURL, using: app) {
      label
    }
  }
}
