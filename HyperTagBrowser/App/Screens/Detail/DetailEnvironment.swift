// created on 4/5/25 by robinsr

import SwiftUI

extension EnvironmentValues {
  var detailEnv: DetailScreenViewModel {
    get { self[DetailScreenViewModelEnvironmentKey.self] }
    set { self[DetailScreenViewModelEnvironmentKey.self] = newValue }
  }
}

struct DetailScreenViewModelEnvironmentKey: EnvironmentKey {
  static let defaultValue = DetailScreenViewModel()
}
