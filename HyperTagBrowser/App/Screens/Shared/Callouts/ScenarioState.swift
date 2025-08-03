// created on 4/26/25 by robinsr

import SwiftUI

enum ScenarioState: String, CaseIterable, Sendable {
  case triggered
  case ok
}

extension ContainerValues {
  @Entry var scenarioState: ScenarioState = .ok
  @Entry var scenarioName: String = "None"
  @Entry var scenarioId: String = .randomIdentifier(12)
}
