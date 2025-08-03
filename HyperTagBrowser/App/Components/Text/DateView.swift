// created on 12/6/24 by robinsr

import SwiftUI

struct DateView: View {
  let date: Date
  var template: String = "%@"
  
  var formatted: String {
    String(format: template, Self.fmt(date))
  }
  
  var body: some View {
    Text(formatted)
  }
  
  static func fmt(_ date: Date) -> String {
    date.formatted(date: .numeric, time: .omitted)
  }
}

#Preview {
  DateView(date: .now)
    .padding()
}
