// created on 10/26/26 by robinsr

import Foundation

@testable import HyperTagBrowser

/// Keeps everything in memory so tests can assert on spans, timings, and statements.
/// Register with `Container.shared.metricsRecorder.register { recorder }` and
/// `Container.shared.metricsRecorder.reset()` afterwards.
final class RecordingMetricsRecorder: MetricsRecorder {
  let spans: SpanBuffer
  let timings = TimingAggregator()
  let statements = StatementRegistry()

  private let emitter: SpanEmitter

  init() {
    let spans = SpanBuffer()
    self.spans = spans
    emitter = SpanEmitter(signposter: .disabled, onStop: { spans.append($0) })
  }

  func span(_ name: StaticString, tags: MetricTags) -> MetricSpan {
    emitter.start(name, tags: tags, parent: nil)
  }

  func timing(_ name: String, ms: Double, tags: MetricTags) {
    timings.record(name, ms: ms, tags: tags)
  }

  func register(statement: SQLStatementInfo) {
    statements.register(statement)
  }

  func flush() {}
  func shutdown(timeout: Duration) {}
}
