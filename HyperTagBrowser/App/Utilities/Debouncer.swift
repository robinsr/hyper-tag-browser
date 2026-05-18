// created on 11/6/25 by robinsr

actor DataOperationDebouncer<T: Sendable> {
  private var task: Task<Void, Never>?
  private let delay: Duration
  private let operation: (T) async -> Void

  init(delay: Duration, operation: @escaping (T) async -> Void) {
    self.delay = delay
    self.operation = operation
  }

  func debounce(data: T) {
    // Cancel the previous task if it exists (resetting the timeout)
    task?.cancel()

    // Create a new task that will execute the operation after the delay
    task = Task {
      do {
        try await Task.sleep(for: delay)
        // Check for cancellation before executing the operation
        try Task.checkCancellation()
        await operation(data)
      } catch {
        // Task was cancelled, do nothing
      }
    }
  }
  
  // Optional: Call this to immediately execute the pending task or cancel it if needed
  func flush() {
    task?.cancel()
    // If you wanted to execute it immediately instead of cancelling, you'd need a different mechanism
  }
}


actor OperationDebouncer {
  private var task: Task<Void, Never>?
  private let delay: Duration
  private let operation: () async -> Void

  init(delay: Duration, operation: @escaping () async -> Void) {
    self.delay = delay
    self.operation = operation
  }

  func debounce() {
    // Cancel the previous task if it exists (resetting the timeout)
    task?.cancel()

    // Create a new task that will execute the operation after the delay
    task = Task {
      do {
        try await Task.sleep(for: delay)
        // Check for cancellation before executing the operation
        try Task.checkCancellation()
        await operation()
      } catch {
        // Task was cancelled, do nothing
      }
    }
  }
  
  // Optional: Call this to immediately execute the pending task or cancel it if needed
  func flush() {
    task?.cancel()
    // If you wanted to execute it immediately instead of cancelling, you'd need a different mechanism
  }
}
