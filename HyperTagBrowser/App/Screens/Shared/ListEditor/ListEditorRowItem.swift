// created on 4/23/25 by robinsr

import SwiftUI

/**
 * Displays the text value and selected-ness of a tag in the picker
 */
struct ListEditorRowItem<Content: View>: View  {
  
  @Binding var focus: ListEditorFocusable
  let eq: ListEditorFocusable
  
  @ViewBuilder
  let content: (Bool) -> (Content)
  
  var isFocused: Bool { focus.id == eq.id }
  
  var body: some View {
    HStack(alignment: .center) {
      content(isFocused)
      Spacer()
    }
    .padding(.vertical, 5)
    .background {
      Color.primary.opacity(isFocused ? 0.2 : 0.0)
    }
    .onTapGesture {
      focus = eq
    }
  }
}
