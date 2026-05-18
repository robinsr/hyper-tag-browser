// created on 5/2/25 by robinsr

import Foundation

extension DispatchQueue {
  
  @MainActor
  func asyncAfter(_ duration: Duration, execute: @escaping @Sendable () -> Void) {
    asyncAfter(deadline: .now() + duration.toTimeInterval, execute: execute)
  }

  @MainActor
  func asyncAfter(_ duration: Duration, execute: DispatchWorkItem) {
    asyncAfter(deadline: .now() + duration.toTimeInterval, execute: execute)
  }
}


extension DispatchWorkItem {

  /**
   * Calls ``Dispatch/DispatchWorkItem/notify(queue:execute:)`` to schedule the execution of the specified work item,
   * with the specified quality-of-service, flags, and `DispatchQueue`, after the completion
   * of the current work item. Returns the **new** `DispatchWorkItem` for further chaining
   */
  func chainTask(
    dispatchOn queue: DispatchQueue = .main,
    qos: DispatchQoS = .userInitiated,
    flags: DispatchWorkItemFlags = [],
    _ work: @escaping () -> Void
  ) -> DispatchWorkItem {
    let workItem = DispatchWorkItem(qos: qos, flags: flags, block: work)
  
    self.notify(qos: qos, flags: flags, queue: queue) {
      workItem.perform()
    }

    return workItem
  }
  
  func chainTask(
    dispatchOn queue: DispatchQueue = .main,
    qos: DispatchQoS = .userInitiated,
    flags: DispatchWorkItemFlags = [],
    _ workItem: DispatchWorkItem
  ) -> Self {
    self.notify(qos: qos, flags: flags, queue: queue) {
      workItem.perform()
    }

    return self
  }
}
