// created on 4/26/25 by robinsr

import SwiftUI


struct FirstTrueScenarioView<Content: View>: View {
  @ViewBuilder let content: Content
  
  func subviewDescription(_ values: ContainerValues) -> String {
    "\(values.scenarioId) (\(values.scenarioName)): \(values.scenarioState)"
  }

  var body: some View {
    LazyVStack {
      Group(subviews: content) { subviews in
        let triggered = subviews.filter {
          $0.containerValues.scenarioState == .triggered
        }
        
        if let firstView = triggered.first {
          firstView
        }
      }
    }
  }
}
