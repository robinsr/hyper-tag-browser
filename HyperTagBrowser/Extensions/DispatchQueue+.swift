// created on 5/2/25 by robinsr

import Foundation

extension DispatchQueue {
  func asyncAfter(_ duration: Duration, execute: @escaping () -> Void) {
    asyncAfter(deadline: .now() + duration.toTimeInterval, execute: execute)
  }

  func asyncAfter(_ duration: Duration, execute: DispatchWorkItem) {
    asyncAfter(deadline: .now() + duration.toTimeInterval, execute: execute)
  }
}


extension DispatchWorkItem {

  /**
   * Calls ``DispatchWorkItem/notify`` to schedule the execution of the specified work item,
   * with the specified quality-of-service, flags, and `DispatchQueue`, after the completion
   * of the current work item. Returns the work item for further chaining
   */
  func chainTask(
    _ nextWorkItem: DispatchWorkItem,
    qos: DispatchQoS = .userInitiated,
    flags: DispatchWorkItemFlags = [],
    usingQueue queue: DispatchQueue = .main
  ) -> DispatchWorkItem {
    self.notify(qos: qos, flags: flags, queue: queue) {
      nextWorkItem.perform()
    }

    return nextWorkItem
  }
}
