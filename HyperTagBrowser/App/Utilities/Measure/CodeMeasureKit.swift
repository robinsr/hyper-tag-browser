// created on 12/6/24 by robinsr

  //
  //  CodeMeasureKit.swift
  //  CodeMeasureKit
  //

  import Foundation
  import Combine
  import Factory

  /// A global flag that enables or disables performance measurement.
  /// - Note: If `isEnabled` is `false`, all calls to `measureCallRate`
  ///   will be ignored.
  nonisolated(unsafe) public var measurementEnabled = true

  /// Measures the call rate of a given code block.
  ///
  /// This function is designed to be used in methods or blocks of code
  /// where you want to track how often they are called. The function stores
  /// the call count based on the file, function, and line where it is
  /// invoked.
  ///
  /// - Parameters:
  ///   - fileName: The name of the file where the call is made. This
  ///     defaults to the current file using `#file`.
  ///   - functionName: The name of the function where the call is made.
  ///     This defaults to the current function using `#function`.
  ///   - line: The line number where the call is made. This defaults
  ///     to the current line using `#line`.
  ///
  /// - Important: The measurement only occurs if `isEnabled` is `true`.
  public func measureCallRate(
      fileName: StaticString = #file,
      functionName: StaticString = #function,
      line: UInt = #line
  ) {
      guard measurementEnabled else { return }
      MeasureCallRateStorage
          .shared
          .callRateMeter(fileName: fileName, functionName: functionName, line: line)
          .recordCall()
  }

  /// Measures the execution time of a synchronous code block and logs the result.
  ///
  /// This function is used to track the time it takes for a code block to execute,
  /// providing performance insights. If measurement is disabled (`isEnabled = false`),
  /// the block will be executed without tracking.
  ///
  /// - Parameters:
  ///   - fileName: The name of the file where this function is called. Defaults to `#file`.
  ///   - functionName: The name of the function where this function is called. Defaults to `#function`.
  ///   - line: The line number where this function is called. Defaults to `#line`.
  ///   - block: The code block whose execution time should be measured.
  /// - Returns: The result of the executed block.
  /// - Throws: Re-throws any error that may occur inside the block.
  /// - Important: This method only measures execution time if `isEnabled` is set to `true`.
  @discardableResult
  public func measureExecutionTime<T>(
      fileName: StaticString = #file,
      functionName: StaticString = #function,
      line: UInt = #line,
      block: () throws -> T
  ) rethrows -> T {
      guard measurementEnabled else { return try block() }
      return try MeasureCallRateStorage
          .shared
          .executionTimeMeter(fileName: fileName, functionName: functionName, line: line)
          .execute(block)
  }

  /// Measures the execution time of an asynchronous code block and logs the result.
  ///
  /// This function is used to track the time it takes for an asynchronous code block to
  /// execute, providing performance insights. If measurement is disabled (`isEnabled = false`),
  /// the block will be executed without tracking.
  ///
  /// - Parameters:
  ///   - fileName: The name of the file where this function is called. Defaults to `#file`.
  ///   - functionName: The name of the function where this function is called. Defaults to `#function`.
  ///   - line: The line number where this function is called. Defaults to `#line`.
  ///   - block: The asynchronous code block whose execution time should be measured.
  /// - Returns: The result of the executed asynchronous block.
  /// - Throws: Re-throws any error that may occur inside the block.
  /// - Important: This method only measures execution time if `isEnabled` is set to `true`.
  @discardableResult
  public func measureExecutionTime<T>(
      fileName: StaticString = #file,
      functionName: StaticString = #function,
      line: UInt = #line,
      block: () async throws -> T
  ) async rethrows -> T {
      guard measurementEnabled else { return try await block() }
      return try await MeasureCallRateStorage
          .shared
          .executionTimeMeter(fileName: fileName, functionName: functionName, line: line)
          .execute(block)
  }


  /// A singleton class responsible for managing call rate meters and
  /// triggering updates.
  ///
  /// This class maintains a dictionary of `CallRateMeter` objects, one for
  /// each file/function/line combination. It also uses a timer to trigger
  /// periodic updates of the call rate.
  private final class MeasureCallRateStorage: @unchecked Sendable {
      /// The shared instance of `MeasureCallRateStorage` (singleton).
      static let `shared` = MeasureCallRateStorage()

      /// A thread-safe queue used for synchronizing access to the storage.
      private let queue = UnfairQueue()

      /// A Combine cancellable for handling the periodic timer events.
      private var cancellable: AnyCancellable?

      /// The storage dictionary that maps a unique string (file:function:line)
      /// to `CallRateMeter` instances.
      private var callRateMeterStorage: [String: CallRateMeter] = [:]
      private var executionTimeMeterStorage: [String: ExecutionTimeMeter] = [:]

      /// Initializes the `MeasureCallRateStorage` and starts a timer that
      /// triggers every second. On each timer tick, it updates the call rate
      /// for all stored meters.
      private init() {
          cancellable = Foundation
              .Timer
              .publish(every: 1, on: .main, in: .default)
              .autoconnect()
              .sink { [weak self] _ in self?.didTrigger() }
      }

      /// Triggered by the periodic timer to update all call rate meters.
      ///
      /// This method iterates over all stored meters and calls their
      /// `didUpdate()` method.
      private func didTrigger() {
          let callRateMeters = queue.sync { callRateMeterStorage.values }
          callRateMeters.forEach { $0.didUpdate() }

          let executionTimeMeters = queue.sync { executionTimeMeterStorage.values }
          executionTimeMeters.forEach { $0.didUpdate() }
      }

      /// Retrieves or creates a `CallRateMeter` for the specified file,
      /// function, and line.
      ///
      /// If a meter already exists for the given file/function/line
      /// combination, it is returned. Otherwise, a new `CallRateMeter` is
      /// created, stored, and returned.
      ///
      /// - Parameters:
      ///   - fileName: The name of the file where the call is being measured.
      ///   - functionName: The name of the function where the call is
      ///     being measured.
      ///   - line: The line number where the call is being measured.
      /// - Returns: A `CallRateMeter` instance corresponding to the
      ///   file, function, and line.
      func callRateMeter(
          fileName: StaticString,
          functionName: StaticString,
          line: UInt
      ) -> CallRateMeter {
          let key = "\(fileName):\(functionName):\(line)"
          return queue.sync {
              if let meter = callRateMeterStorage[key] {
                  return meter
              } else {
                  let meter = CallRateMeter(
                      fileName: fileName,
                      functionName: functionName,
                      line: line
                  )
                  callRateMeterStorage[key] = meter
                  return meter
              }
          }
      }

      func executionTimeMeter(
          fileName: StaticString,
          functionName: StaticString,
          line: UInt
      ) -> ExecutionTimeMeter {
          let key = "\(fileName):\(functionName):\(line)"
          return queue.sync {
              if let meter = executionTimeMeterStorage[key] {
                  return meter
              } else {
                  let meter = ExecutionTimeMeter(
                      fileName: fileName,
                      functionName: functionName,
                      line: line
                  )
                  executionTimeMeterStorage[key] = meter
                  return meter
              }
          }
      }
  }

  /// A class that tracks the call rate of a specific code block.
  ///
  /// Each `CallRateMeter` tracks the number of times a specific code block
  /// (identified by file, function, and line) is called over time, and
  /// records both the maximum and minimum call counts within each update
  /// cycle.
  private final class CallRateMeter {
    private let logger = EnvContainer.shared.logger("CodeMeasureKit.CallRateMeter")
    
      /// The name of the file where this meter is measuring calls.
      private let fileName: StaticString

      /// The name of the function where this meter is measuring calls.
      private let functionName: StaticString

      /// The line number where this meter is measuring calls.
      private let line: UInt

      /// A thread-safe queue used for synchronizing access to call count data.
      private let queue = UnfairQueue()

      /// The current number of calls since the last update.
      private var callCount: Int = 0

      /// The maximum number of calls within an update cycle.
      private var maxCallCount: Int = 0

      /// The minimum number of calls within an update cycle.
      private var minCallCount: Int = 0

      private let sourceLine: String

      /// Initializes a new `CallRateMeter` for a given file, function, and line.
      ///
      /// - Parameters:
      ///   - fileName: The name of the file where calls are being tracked.
      ///   - functionName: The name of the function where calls are being
      ///     tracked.
      ///   - line: The line number where calls are being tracked.
      init(
          fileName: StaticString,
          functionName: StaticString,
          line: UInt
      ) {
          self.fileName = fileName
          self.functionName = functionName
          self.line = line
          self.sourceLine = "\(URL(string: "\(fileName)")?.lastPathComponent ?? "\(fileName)"):\(functionName):\(line)"
      }

      /// Updates the call rate statistics and resets the call count.
      ///
      /// This method is typically called on a timer (once per second) to
      /// update the maximum and minimum call counts and reset the current
      /// call count for the next period.
      func didUpdate() {
          queue.sync { [callCount, maxCallCount, minCallCount, sourceLine] in
              self.maxCallCount = max(callCount, maxCallCount)
              self.minCallCount = min(callCount, minCallCount)
            logger.emit(.debug,
                  "Call rate of [\(sourceLine)] updated with count:\(callCount) max:\(maxCallCount) min:\(minCallCount)."
              )
              self.callCount = 0
          }
      }

      /// Increments the function call count.
      ///
      /// Call this method inside the function you want to monitor to track
      /// how often that function is being invoked.
      func recordCall() {
          queue.sync { callCount += 1 }
      }
  }

  private final class ExecutionTimeMeter {
    private let logger = EnvContainer.shared.logger("CodeMeasureKit.ExecutionTimeMeter")
    
      /// The name of the file where this meter is measuring calls.
      private let fileName: StaticString

      /// The name of the function where this meter is measuring calls.
      private let functionName: StaticString

      /// The line number where this meter is measuring calls.
      private let line: UInt

      /// A thread-safe queue used for synchronizing access to call count data.
      private let queue = UnfairQueue()

      private let sourceLine: String
      private let subject: PassthroughSubject<TimeInterval, Never> = .init()

      /// The current number of calls since the last update.
      private var lastDurations: [TimeInterval] = []

      /// The maximum number of calls within an update cycle.
      private var maxDuration: TimeInterval = 0

      /// The minimum number of calls within an update cycle.
      private var minDuration: TimeInterval = 0

      /// Initializes a new `CallRateMeter` for a given file, function, and line.
      ///
      /// - Parameters:
      ///   - fileName: The name of the file where calls are being tracked.
      ///   - functionName: The name of the function where calls are being
      ///     tracked.
      ///   - line: The line number where calls are being tracked.
      init(
          fileName: StaticString,
          functionName: StaticString,
          line: UInt
      ) {
          self.fileName = fileName
          self.functionName = functionName
          self.line = line
          self.sourceLine = "\(URL(string: "\(fileName)")?.lastPathComponent ?? "\(fileName)"):\(functionName):\(line)"
      }

      func didUpdate() {
          queue.sync { [lastDurations, maxDuration, minDuration, sourceLine] in
              let maxLastDuration = lastDurations.max() ?? maxDuration
              let averageLastDuration: TimeInterval = lastDurations.count > 0
              ? (lastDurations.reduce(TimeInterval(0)) { partialResult, value in partialResult + value }) / TimeInterval(lastDurations.endIndex)
              : 0
              let minLastDuration = lastDurations.min() ?? minDuration
              self.maxDuration = max(maxLastDuration, maxDuration)
              self.minDuration = min(minLastDuration, minDuration)
            logger.emit(.debug.off,
                  "Call duration of [\(sourceLine)] updated with last average:\(averageLastDuration) max:\(maxDuration) min:\(minDuration)."
              )
              self.lastDurations = []
          }
      }

      func execute<T>(
          _ block: () throws -> T
      ) rethrows -> T {
          let currentTime = Date()
          defer {
              let diff = currentTime.timeIntervalSinceNow
              queue.sync { lastDurations.append(diff) }
          }
          let result = try block()
          return result
      }

      func execute<T>(
          _ block: () async throws -> T
      ) async rethrows -> T {
          let currentTime = Date()
          defer {
              let diff = abs(currentTime.timeIntervalSinceNow)
              queue.sync { lastDurations.append(diff) }
          }
          let result = try await block()
          return result
      }
  }
