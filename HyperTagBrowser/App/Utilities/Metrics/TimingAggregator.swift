// created on 10/26/26 by robinsr

import Foundation
import Synchronization

enum TimingBuckets {
  /// Inclusive upper bounds in milliseconds. Fixed so bucket counts can be summed across
  /// windows and sessions. Changing these requires a new `timings` schema version.
  static let upperBoundsMs: [Double] = [
    0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100, 250, 500, 1_000, 10_000, .infinity,
  ]

  static func index(for ms: Double) -> Int {
    upperBoundsMs.firstIndex { ms <= $0 } ?? upperBoundsMs.count - 1
  }
}


struct TimingKey: Hashable, Sendable {
  let name: String
  let tags: MetricTags
}


struct TimingAggregate: Equatable, Sendable {
  let key: TimingKey
  var count = 0
  var sumMs = 0.0
  var minMs = Double.infinity
  var maxMs = 0.0
  var buckets = [Int](repeating: 0, count: TimingBuckets.upperBoundsMs.count)

  init(key: TimingKey) {
    self.key = key
  }

  mutating func add(_ ms: Double) {
    count += 1
    sumMs += ms
    minMs = min(minMs, ms)
    maxMs = max(maxMs, ms)
    buckets[TimingBuckets.index(for: ms)] += 1
  }
}


/// Accumulates timings per `(name, tags)` until drained by a flush.
final class TimingAggregator: Sendable {
  static let overflowName = "metrics.overflow"

  private let maxKeys: Int
  private let state = Mutex<[TimingKey: TimingAggregate]>([:])

  init(maxKeys: Int = 5_000) {
    self.maxKeys = maxKeys
  }

  func record(_ name: String, ms: Double, tags: MetricTags = [:]) {
    state.withLock { aggregates in
      var key = TimingKey(name: name, tags: tags)

      if aggregates[key] == nil && aggregates.count >= maxKeys {
        key = TimingKey(name: Self.overflowName, tags: [:])
      }

      aggregates[key, default: TimingAggregate(key: key)].add(ms)
    }
  }

  func drain() -> [TimingAggregate] {
    state.withLock { aggregates in
      defer { aggregates.removeAll(keepingCapacity: true) }
      return Array(aggregates.values)
    }
  }
}
