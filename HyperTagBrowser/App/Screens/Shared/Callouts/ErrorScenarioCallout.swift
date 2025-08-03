// created on 4/26/25 by robinsr

import SwiftUI


struct ErrorScenarioCallout: View {
  var id: String
  var isTrue: () -> Bool
  var title: String
  var help: String
  var icon: SymbolIcon
  
  var scenarioState: ScenarioState {
    isTrue() ? .triggered : .ok
  }
  
  var body: some View {
    NoContentView(title: title, help: help, icon: icon)
      .containerValue(\.scenarioState, scenarioState)
      .containerValue(\.scenarioName, title)
      .containerValue(\.scenarioName, id)
  }
}
