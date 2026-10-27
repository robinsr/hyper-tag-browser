// created on 10/26/26 by robinsr

import Foundation

/// Low-cardinality labels attached to spans and timings. Never put paths, ids, or user input here.
typealias MetricTags = [String: String]


extension Dictionary where Key == String, Value == String {
  /// JSON object with sorted keys, so equal tag sets always produce identical text.
  var canonicalJSON: String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    guard let data = try? encoder.encode(self) else { return "{}" }
    return String(decoding: data, as: UTF8.self)
  }
}


extension ContinuousClock.Instant {
  /// Milliseconds elapsed between this instant and now.
  var elapsedMs: Double {
    (ContinuousClock.now - self).milliseconds
  }
}


extension Duration {
  var milliseconds: Double {
    let parts = components
    return Double(parts.seconds) * 1_000 + Double(parts.attoseconds) / 1e15
  }
}
