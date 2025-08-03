// created on 12/10/24 by robinsr

import SwiftUI


struct ListControlsHint: View {
  var leftControl: KeyBinding = .listEditorLeft
  var rightControl: KeyBinding = .listEditorRight
  var selectControl: KeyEquivalent = .return
  
  
  var body: some View {
    HStack(spacing: 0) {
      KeyBindingHintView(binding: leftControl)
      Text(verbatim: " and ")
      KeyBindingHintView(binding: rightControl)
      Text(verbatim: " to navigate, ")
      ShortcutBox {
        Image(systemName: selectControl.symbolName)
          .font(.system(size: 10))
          .bold()
          .padding(.vertical, 2)
      }
      
      Text(verbatim: " to select")
    }
  }
  
  func ShortcutBox(@ViewBuilder content: @escaping () -> some View) -> some View {
    ZStack{
      content()
    }
    .padding(.leading, 4)
    .padding(.trailing, 2)
    .padding(.vertical, 2)
    .background {
      RoundedRectangle(cornerRadius: 3)
        .fill(.gray.opacity(0.2))
        .stroke(.gray.opacity(0.5), lineWidth: 0.4)
    }
  }
}



#Preview("ListControlsHint") {
  VStack {
    ListControlsHint(leftControl: .listEditorLeft, rightControl: .listEditorRight, selectControl: .tab)
    ListControlsHint(leftControl: .gridCursorLeft, rightControl: .gridCursorRight, selectControl: .delete)
    ListControlsHint(leftControl: .goBack, rightControl: .goForward, selectControl: .return)
    ListControlsHint(leftControl: .back, rightControl: .forward, selectControl: .end)
    ListControlsHint(leftControl: .hzPrevItem, rightControl: .hzNextItem, selectControl: .space)
    ListControlsHint(leftControl: .zoomActual, rightControl: .zoomFitted, selectControl: .leftArrow)
    ListControlsHint(leftControl: .showSearch, rightControl: .relocateSelection, selectControl: .rightArrow)
  }
  .scenePadding()
}
