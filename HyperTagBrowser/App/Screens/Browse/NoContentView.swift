// created on 10/16/24 by robinsr

import SwiftUI

struct NoContentView : View {
  var title: String
  var help: String
  var icon: SymbolIcon = .eyeslash
  
  var body: some View {
    VStack {
      ContentUnavailableView {
        Label(title, icon)
      } description: {
        Text(help)
      }
    }
  }
}
