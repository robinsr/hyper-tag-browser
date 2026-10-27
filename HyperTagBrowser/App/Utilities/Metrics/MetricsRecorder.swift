// created on 10/26/26 by robinsr

import Foundation

/// Records performance data. Resolve with `Container.shared.metricsRecorder()`.
///
/// - Spans: low-volume named steps (e.g. one per indexing pipeline stage). Shown in
///   Instruments and persisted individually.
/// - Timings: high-volume durations (per file, per SQL statement). Aggregated per
///   `(name, tags)` per flush window.
protocol MetricsRecorder: Sendable {
  func span(_ name: StaticString, tags: MetricTags) -> MetricSpan
  func timing(_ name: String, ms: Double, tags: MetricTags)
  /// Records the text for a SQL statement hash so timings can be joined back to SQL.
  func register(statement: SQLStatementInfo)
  /// Writes buffered data now.
  func flush()
  /// Final flush and session end, waiting at most `timeout`.
  func shutdown(timeout: Duration)
}


extension MetricsRecorder {
  func span(_ name: StaticString) -> MetricSpan {
    span(name, tags: [:])
  }

  func timing(_ name: String, ms: Double) {
    timing(name, ms: ms, tags: [:])
  }

  func shutdown() {
    shutdown(timeout: .milliseconds(200))
  }

  /// Runs `body` and records its duration as a timing named `name`.
  func time<T>(_ name: String, tags: MetricTags = [:], _ body: () throws -> T) rethrows -> T {
    let start = ContinuousClock.now
    defer { timing(name, ms: start.elapsedMs, tags: tags) }
    return try body()
  }
}


/// Used when metrics are disabled, in tests, and in previews.
final class NoopMetricsRecorder: MetricsRecorder {
  func span(_ name: StaticString, tags: MetricTags) -> MetricSpan {
    SpanEmitter.silent.start(name, tags: tags, parent: nil)
  }

  func timing(_ name: String, ms: Double, tags: MetricTags) {}
  func register(statement: SQLStatementInfo) {}
  func flush() {}
  func shutdown(timeout: Duration) {}
}
