// created on 10/26/26 by robinsr

import Foundation
import Nimble
import Testing

@testable import HyperTagBrowser

@Suite("TimingAggregator")
struct TimingAggregatorTest {

  @Test("bucket index uses inclusive upper bounds")
  func test_bucket_index() {
    expect(TimingBuckets.upperBoundsMs).to(haveCount(16))
    expect(TimingBuckets.index(for: 0)).to(equal(0))
    expect(TimingBuckets.index(for: 0.05)).to(equal(0))
    expect(TimingBuckets.index(for: 0.051)).to(equal(1))
    expect(TimingBuckets.index(for: 1)).to(equal(4))
    expect(TimingBuckets.index(for: 10_000)).to(equal(14))
    expect(TimingBuckets.index(for: 10_001)).to(equal(15))
  }

  @Test("record accumulates count, sum, min, max and buckets")
  func test_record_accumulates() throws {
    let aggregator = TimingAggregator()
    aggregator.record("a", ms: 2, tags: ["k": "v"])
    aggregator.record("a", ms: 8, tags: ["k": "v"])

    let drained = aggregator.drain()
    expect(drained).to(haveCount(1))

    let aggregate = try #require(drained.first)
    expect(aggregate.key).to(equal(TimingKey(name: "a", tags: ["k": "v"])))
    expect(aggregate.count).to(equal(2))
    expect(aggregate.sumMs).to(equal(10))
    expect(aggregate.minMs).to(equal(2))
    expect(aggregate.maxMs).to(equal(8))
    expect(aggregate.buckets[5]).to(equal(1))          // 2ms  -> <= 2.5
    expect(aggregate.buckets[7]).to(equal(1))          // 8ms  -> <= 10
    expect(aggregate.buckets.reduce(0, +)).to(equal(2))
  }

  @Test("different tags produce separate aggregates")
  func test_tags_separate_keys() {
    let aggregator = TimingAggregator()
    aggregator.record("sql", ms: 1, tags: ["stmt": "aaa"])
    aggregator.record("sql", ms: 1, tags: ["stmt": "bbb"])
    expect(aggregator.drain()).to(haveCount(2))
  }

  @Test("drain resets the aggregator")
  func test_drain_resets() {
    let aggregator = TimingAggregator()
    aggregator.record("a", ms: 1)
    _ = aggregator.drain()
    expect(aggregator.drain()).to(beEmpty())
  }

  @Test("concurrent records are all counted")
  func test_concurrent_records() async {
    let aggregator = TimingAggregator()
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<100 {
        group.addTask {
          for _ in 0..<100 { aggregator.record("a", ms: 1) }
        }
      }
    }
    expect(aggregator.drain().first?.count).to(equal(10_000))
  }

  @Test("keys beyond the cap fold into metrics.overflow")
  func test_overflow() {
    let aggregator = TimingAggregator(maxKeys: 2)
    aggregator.record("a", ms: 1)
    aggregator.record("b", ms: 1)
    aggregator.record("c", ms: 1)
    aggregator.record("d", ms: 1)
    aggregator.record("a", ms: 1)

    let byName = Dictionary(
      uniqueKeysWithValues: aggregator.drain().map { ($0.key.name, $0.count) })
    expect(byName).to(equal(["a": 2, "b": 1, TimingAggregator.overflowName: 2]))
  }

  @Test("canonicalJSON sorts keys")
  func test_canonical_json() {
    let tags: MetricTags = ["z": "1", "a": "2"]
    expect(tags.canonicalJSON).to(equal(#"{"a":"2","z":"1"}"#))
  }
}
