// created on 5/5/25 by robinsr

import SwiftUI


struct BrowsePath: View {
  @Environment(\.dispatcher) var dispatch
  @Environment(\.location) var location
  @Environment(\.cursorState) var cursorState
  @Environment(\.dbContentItemParameters) var query
  
  var pathBarURL: URL {
    cursorState.anyOneSelected?.url ?? location
  }
  
  var body: some View {
    HStack(alignment: .center) {
      
      PathContrlNSView(url: .constant(pathBarURL)) { url in
        dispatch(.navigate(to: .forURL(url.filepath)))
      }
      
      Group {
        Label("All Descendants", .stackedItems)
          .visible(pathBarURL.isDirectory && query.mode.type == .recursive)
        
        Label("Contents", .stackedItems)
          .visible(pathBarURL.isDirectory && query.mode.type == .immediate)
      }
      .styleClass(.statusbar)
    }
    
  }
}
