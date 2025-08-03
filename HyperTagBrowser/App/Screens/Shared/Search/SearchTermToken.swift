// created on 4/8/25 by robinsr

import SwiftUI

struct SearchTermToken: View {
  let term: SearchTerm
  
  var body: some View {
    VStack {
      Text(term.rawValue)
      Text(term.asFilter.description)
    }
    .padding(4)
    .background(Color.secondary, in: RoundedRectangle(cornerRadius: 5))
    .colorScheme(.dark)
  }
}
