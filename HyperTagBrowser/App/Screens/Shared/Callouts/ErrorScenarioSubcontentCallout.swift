// created on 4/26/25 by robinsr

import SwiftUI

struct ErrorScenarioSubcontentCallout<Content: View>: View {
  var id: String
  var isTrue: () -> Bool
  var title: String
  var help: String
  var icon: SymbolIcon
  var content: (NoContentView) -> Content
  
  var scenarioState: ScenarioState {
    isTrue() ? .triggered : .ok
  }
  
  var body: some View {
    content(
      NoContentView(title: title, help: help, icon: icon)
    )
    .containerValue(\.scenarioState, scenarioState)
    .containerValue(\.scenarioName, title)
    .containerValue(\.scenarioName, id)
  }
}
