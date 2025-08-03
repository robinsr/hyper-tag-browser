// created on 4/18/25 by robinsr

import Factory
import SwiftUI


struct ToastBody<Content: View>: View {
  
  @Injected(\Container.themeProvider) var theme
  
  let content: () -> (Content)
  
  var toastShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: 10, style: .continuous)
  }
  
  var body: some View {
    content()
      .fixedSize(horizontal: false, vertical: false)
      //.padding(.horizontal, 14)
      .padding(.horizontal, 8)
      //.padding(.vertical, 8)
      .padding(.vertical, 3)
      .frame(minHeight: 50)
      .frame(maxWidth: 480, alignment: .leading)
      .background(theme.background(.dark).opacity(0.75))
      .clipShape(toastShape)
      .overlay(toastShape.stroke(Color.gray.opacity(0.2), lineWidth: 1))
      .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
      .compositingGroup()
  }
}


struct AlertToastView: View {
  @Injected(\Container.themeProvider) var theme
  @Environment(\.dispatcher) var dispatch
  
  let message: AppMessage
  
  var alertIcon: SymbolIcon {
    message.level.alertIcon
  }
  
  var iconColor: Color {
    message.level.alertColor
  }
  
  var foregroundColor: Color {
    theme.foreground(.dark)
  }
  
  var body: some View {
    ToastBody {
      VStack(alignment: .leading, spacing: 5) {
        HStack(alignment: .center, spacing: 5) {
          AlertIcon
          AlertHeadline
        }
        AlertMessage
          .padding(.leading, 22)
      }
    }
    .onTapGesture {
      dispatch(.clearMessage(message))
    }
  }
  
  var AlertIcon: some View {
    Image(alertIcon)
      .resizable()
      .scaledToFit()
      .frame(width: 18, height: 18)
      .foregroundColor(iconColor)
  }
  
  var AlertHeadline: some View {
    Text(message.level.title)
      .foregroundStyle(foregroundColor)
      .font(.system(size: 16))
      .fontWeight(.medium)
  }
  
  var AlertMessage: some View {
    Text(.init(message.body))
      .foregroundStyle(foregroundColor.lighten(by: 0.5))
      .font(.system(size: 12))
      .truncationMode(.tail)
      .selectable()
  }
}





#Preview("AlertToastView", traits: .fixedLayout(width: 600, height: 800)) {
  
  @Previewable @State var messages: [AppMessage] = [
    .info(TestData.lorem(sentences: .random(in: 2...4))),
    .ok(TestData.lorem(sentences: .random(in: 2...4))),
    .warning(TestData.lorem(sentences: .random(in: 2...4))),
    .error(TestData.lorem(sentences: .random(in: 2...4))),
    .fatal(TestData.lorem(sentences: .random(in: 2...4))),
  ]
  
  BackgroundGradientView(color: .accentColor, intensity: 0.999) {
    
  }
  .frame(width: 600, height: 800, alignment: .bottom)
  .overlay(alignment: .topLeading) {
    VStack(spacing: 10) {
      ForEach(messages, id: \.id) { message in
        AlertToastView(message: message)
      }
    }
    .padding(20)
  }
  .overlay(alignment: .bottom) {
    ToastBody {
      Text("I'm a toast! 🥂")
        .font(.title)
        .foregroundStyle(.white)
    }
  }
}
