// created on 2/8/25 by robinsr

import Factory
import Foundation

/// Times blocks of code and records them as metrics timings.
struct SelfTimer {

  @Injected(\Container.metricsRecorder) private var metricsRecorder

  /// Records `block`'s duration under the calling file and function's metric name.
  func timeExecution<T>(
    file: String = #file, function: String = #function, block: () throws -> T
  ) rethrows -> T {
    try metricsRecorder.time(MetricSource(file, function).name, block)
  }

  /// Records `block`'s duration under `metric.name`.
  func timeExecution<T>(using metric: MetricSource, block: () throws -> T) rethrows -> T {
    try metricsRecorder.time(metric.name, block)
  }

  /// Records `block`'s duration under `name` with `tags`.
  func timeExecution<T>(named name: String, tags: MetricTags, block: () throws -> T) rethrows -> T {
    try metricsRecorder.time(name, tags: tags, block)
  }

  /// Async variant of ``timeExecution(file:function:block:)``.
  func timeExecution<T>(
    file: String = #file, function: String = #function, block: () async throws -> T
  ) async rethrows -> T {
    let start = ContinuousClock.now
    defer { metricsRecorder.timing(MetricSource(file, function).name, ms: start.elapsedMs) }
    return try await block()
  }
}
