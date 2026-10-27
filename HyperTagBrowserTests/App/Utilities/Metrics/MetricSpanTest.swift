// created on 10/26/26 by robinsr

import Foundation
import Nimble
import OSLog
import Testing

@testable import HyperTagBrowser

@Suite("MetricSpan")
struct MetricSpanTest {

  struct Boom: Error {}

  let buffer = SpanBuffer()

  var emitter: SpanEmitter {
    let buffer = self.buffer
    return SpanEmitter(signposter: .disabled, onStop: { buffer.append($0) })
  }

  @Test("a root span is its own trace")
  func test_root_span_trace() throws {
    let root = emitter.start("root", tags: [:], parent: nil)
    root.stop()

    let record = try #require(buffer.all.first)
    expect(record.traceId).to(equal(record.id))
    expect(record.parentId).to(beNil())
    expect(record.name).to(equal("root"))
    expect(record.outcome).to(equal(.ok))
    expect(record.durationMs).to(beGreaterThanOrEqualTo(0))
  }

  @Test("children share the trace and point at their parent")
  func test_child_span() throws {
    let root = emitter.start("root", tags: [:], parent: nil)
    let child = root.child("child")
    child.stop()
    root.stop()

    let childRecord = try #require(buffer.all.first { $0.name == "child" })
    expect(childRecord.traceId).to(equal(root.id))
    expect(childRecord.parentId).to(equal(root.id))
  }

  @Test("tags given at start and added later are recorded")
  func test_tags() throws {
    let span = emitter.start("tagged", tags: ["mode": "immediate"], parent: nil)
    span.tag("rows", 12)
    span.stop()

    let record = try #require(buffer.all.first)
    expect(record.tags).to(equal(["mode": "immediate", "rows": "12"]))
  }

  @Test("stopping twice records once")
  func test_stop_idempotent() {
    let span = emitter.start("once", tags: [:], parent: nil)
    span.stop()
    span.stop(outcome: .error)
    expect(buffer.all).to(haveCount(1))
    expect(buffer.all.first?.outcome).to(equal(.ok))
  }

  @Test("measure stops with error outcome and rethrows")
  func test_measure_error() {
    let span = emitter.start("failing", tags: [:], parent: nil)
    expect { try span.measure { _ -> Int in throw Boom() } }.to(throwError(errorType: Boom.self))
    expect(buffer.all.first?.outcome).to(equal(.error))
  }

  @Test("measure returns the body's value and stops ok")
  func test_measure_ok() throws {
    let span = emitter.start("ok", tags: [:], parent: nil)
    let value = span.measure { _ in 42 }
    expect(value).to(equal(42))
    expect(buffer.all.first?.outcome).to(equal(.ok))
  }

  @Test("drain empties the buffer")
  func test_buffer_drain() {
    emitter.start("a", tags: [:], parent: nil).stop()
    expect(buffer.drain()).to(haveCount(1))
    expect(buffer.all).to(beEmpty())
  }
}
