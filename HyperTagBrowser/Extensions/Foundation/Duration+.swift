// created on 5/2/25 by robinsr

import Foundation

extension Duration {
  var nanoseconds: Int64 {
    let (seconds, attoseconds) = components
    let secondsNanos = seconds * 1_000_000_000
    let attosecondsNanons = attoseconds / 1_000_000_000
    let (totalNanos, isOverflow) = secondsNanos.addingReportingOverflow(attosecondsNanons)
    return isOverflow ? .max : totalNanos
  }

  var toTimeInterval: TimeInterval { Double(nanoseconds) / 1_000_000_000 }
}
