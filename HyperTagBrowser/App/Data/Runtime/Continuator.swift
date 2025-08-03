// created on 6/3/25 by robinsr

import Foundation
import Observation


struct Continuator: Sendable {
  func withContinousObservation<T>(of value: @escaping @autoclosure () -> T, execute: @escaping (T) -> Void) {
    withObservationTracking {
      execute(value())
    } onChange: {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
        self.withContinousObservation(of: value(), execute: execute)
      }
    }
  }
}


final class ChangeMonitor {
  private var continuator: Continuator

  init() {
    self.continuator = Continuator()
  }

  func observe<T>(_ value: @escaping @autoclosure () -> T, execute: @escaping (T) -> Void) {
    continuator.withContinousObservation(of: value(), execute: execute)
  }

  deinit {
    // Cleanup if needed
  }
}
