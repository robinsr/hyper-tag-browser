// created on 10/28/24 by robinsr

import GRDB
import SwiftUI
import Factory

struct DatabaseErrorView: View {
  typealias ErrorDictionary = [String: Optional<Error>]
  
  @Injected(\PreferencesContainer.userProfile) var userProfile
  
  
  var title = "Something went wrong"
  var help = "An error prevented the app from loading. This is embarrassing..."
  var icon: SymbolIcon = .error
  var errorMap: ErrorDictionary
  
  func describeError(_ error: any Error) -> String {
    String(describing: error.self)
  }
  
  var body: some View {
    FullScreenError {
      NoContentView(title: title, help: help, icon: icon)
    } innerContent: {
      VStack(spacing: 10) {
        ForEach(errorMap.sorted(by: { $0.key < $1.key }), id: \.key) { (query, error) in
          if let error = error {
            ErrorRow(title: "\(query) \(error.localizedDescription)", errorMsg: describeError(error))
          } else {
            ErrorRow(title: query, errorMsg: "No error", color: .green)
          }
        }
        
        Text("Error in database: \(userProfile.dbFile.filepath)")
      }
    }
  }
  
  
  func ErrorRow(title: String, errorMsg: String, color: Color = .red) -> some View {
    HStack(spacing: 10) {
      Group {
        Text(.init("**\(title):** "))
        + Text(.init(errorMsg))
          .foregroundStyle(color)
      }
      .styleClass(.errorDetails)
    }
    .fillFrame(.horizontal, alignment: .leading)
    
  }
}
  
struct FatalErrorView: View {

  @Injected(\Container.clipboardService) var clippy
  
  var title = "Something went wrong"
  var help = "An error prevented the app from loading. This is embarrassing..."
  var icon: SymbolIcon = .error
  var error: Error
  
  @State var showDetails = false
  
  var body: some View {
    FullScreenError {
      NoContentView(title: title, help: help, icon: icon)
    } innerContent: {
      Text(error.localizedDescription)
        .styleClass(.errorDetails)
      
      Button("Copy details") {
        clippy.write(text: error.localizedDescription)
      }
      .buttonStyle(.accessoryBarAction)
    }
  }
}

fileprivate struct FullScreenError<OuterContent: View, InnerContent: View> : View {
  @Environment(\.colorModel) var bgColor
  @Injected(\Container.clipboardService) var clippy
  
  @ViewBuilder let outerContent: () -> OuterContent
  @ViewBuilder let innerContent: () -> InnerContent
  
  @State var showDetails = false
  
  var body: some View {
    VStack(spacing: 20) {
      outerContent()
      
      Button("See details") {
        showDetails.toggle()
      }
      .buttonStyle(.accessoryBarAction)
      
      FoldedPanel(isPresented: $showDetails) {
        VStack(spacing: 20) {
          innerContent()
            .selectable()
        }
      }
      .panelStyle(.darkened)
    }
    .frame(maxWidth: 1200)
    .background {
      Rectangle()
        .fill(.black.opacity(0.5))
    }
    .colorScheme(bgColor.colorScheme)
  }
}
