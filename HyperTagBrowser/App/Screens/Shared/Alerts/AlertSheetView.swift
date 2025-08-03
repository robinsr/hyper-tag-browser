// created on 4/18/25 by robinsr

import SwiftUI


struct AlertViewSheetContent: View, SheetPresentable {
  static let presentation: SheetPresentation = .infoFitted(controls: .none)
  
  @Environment(\.dispatcher) var dispatch  
  
  let message: AppMessage
  
  var buttonText: String {
    switch message.level {
      case .restart: return "Restart"
      default: return "Dismiss"
    }
  }
  
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack(spacing: 20) {
      Label {
        Text(message.level.title)
          .font(.system(size: 24))
      } icon: {
        Image(message.level.alertIcon)
          .foregroundColor(message.level.alertColor)
          .font(.system(size: 30))
      }
      
      Group {
        Text(message.body)
          .fontWeight(.medium)
          .fixedSize(horizontal: false, vertical: true)
          .lineLimit(20)
          .hidden(message.body.isEmpty)
        
        Text(message.details)
          .fixedSize(horizontal: false, vertical: true)
          .opacity(0.8)
          .hidden(message.details.isEmpty)
      }
      .styleClass(.body)
      .selectable()
      .frame(maxWidth: 800)
      
      FullWidth(alignment: .trailing) {
        FormButton(.primary, buttonText) {
          dispatch(.clearMessage(message))
        }
      }
    }
    .padding()
    .focusable()
    .focusEffectDisabled()
    .focused($isFocused)
    .onAppear {
      isFocused = true
    }
    .onKeyPress(.return) {
      dispatch(.clearMessage(message))
      return .handled
    }
    .onKeyPress(.escape) {
      dispatch(.clearMessage(message))
      return .handled
    }
  }
}

#Preview("AlertViewSheetContent", traits: .defaultViewModel, .fixedLayout(width: 600, height: 400)) {
  @Previewable @State var messages: [AppMessage] = TestData.testMessages
  
  VStack {
    Text("Main app content")
  }
  .fillFrame()
  .overlay {
    ForEach(messages, id: \.id) { message in
      AlertViewSheetContent(message: message)
    }
  }
}
