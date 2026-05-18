// created on 6/3/25 by robinsr

import Foundation
import Observation

@MainActor
struct Continuator {
  
  func withContinousObservation<T>(
    of value: @escaping @autoclosure @MainActor @Sendable () -> T,
    execute: @escaping @MainActor @Sendable (T) -> Void
  ) {
    withObservationTracking {
      execute(value())
    } onChange: {
      Task { @MainActor in
        self.withContinousObservation(of: value(), execute: execute)
      }
    }
  }
}

@MainActor
struct ChangeMonitor {
  private var continuator: Continuator

  init() {
    self.continuator = Continuator()
  }

  func observe<T>(
    _ value: @Sendable @escaping @autoclosure () -> T,
    execute: @Sendable @escaping (T) -> Void
  ) {
    Task {
      continuator.withContinousObservation(of: value(), execute: execute)
    }
  }
}
