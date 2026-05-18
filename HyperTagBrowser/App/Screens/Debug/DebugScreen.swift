// created on 11/28/25 by robinsr

import SwiftUI

struct DebugScreen: Scene {
  static let screenId = "\(Constants.appname).Debug"
  
  @State var progressValue: Double = 0.877
  
  var body: some Scene {
    Window("Debug", id: Self.screenId) {
      ProgressView(value: progressValue, total: 1.0) // Progress from 0.0 to 1.0
        .progressViewStyle(.linear) // Use a linear style for the bar
        .padding()
    }
  }
}
