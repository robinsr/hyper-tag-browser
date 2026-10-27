// created on 10/26/26 by robinsr

import Factory
import Foundation
import Nimble
import System
import Testing

@testable import HyperTagBrowser

@Suite("Indexing metrics", .serialized, .tags(.indexer))
struct IndexingMetricsTest {

  // Note: HyperTagBrowser and HyperTagBrowserTests each statically link Factory into their own
  // binary (see SQLProfilingTest.swift), so a `Container.shared.metricsRecorder.register` here
  // is never observed by `indexDirectory(at:)`'s root span, which is created via
  // `Container.shared.metricsRecorder()` inside app-target code. `diffDirectoryContents` takes
  // its parent span as an explicit parameter rather than resolving one from Container, so it can
  // be tested directly against a span tree built entirely in this binary.
  @Test("diffDirectoryContents records index.list and index.lookup as children of the given span")
  func test_diff_directory_contents_spans() async throws {
    let recorder = RecordingMetricsRecorder()
    let (service, _) = try await TestSupportDB.setupDB()

    let folder = SystemLocation.tmpDir.appending("indexing-metrics-\(UUID().uuidString)")
    try FileManager.default.createDirectory(
      atPath: folder.string, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: folder.string) }

    for name in ["one.jpg", "two.jpg"] {
      FileManager.default.createFile(
        atPath: folder.appending(name).string, contents: Data([0xFF, 0xD8, 0xFF]))
    }

    let root = recorder.span("index.directory")
    _ = try await service.diffDirectoryContents(
      of: folder, mode: .immediate(.uncached), parent: root)
    root.stop()

    let spans = recorder.spans.all
    expect(Set(spans.map(\.name))).to(equal(["index.directory", "index.list", "index.lookup"]))

    let list = try #require(spans.first { $0.name == "index.list" })
    expect(list.parentId).to(equal(root.id))
    expect(list.traceId).to(equal(root.id))
    expect(list.tags["files"]).to(equal("2"))

    let lookup = try #require(spans.first { $0.name == "index.lookup" })
    expect(lookup.parentId).to(equal(root.id))
    expect(lookup.tags["rows"]).to(equal("0"))
  }

  @Test("indexDirectory indexes new files end to end")
  func test_index_directory_result() async throws {
    let (service, _) = try await TestSupportDB.setupDB()

    let folder = SystemLocation.tmpDir.appending("indexing-metrics-\(UUID().uuidString)")
    try FileManager.default.createDirectory(
      atPath: folder.string, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(atPath: folder.string) }

    for name in ["one.jpg", "two.jpg", "three.jpg"] {
      FileManager.default.createFile(
        atPath: folder.appending(name).string, contents: Data([0xFF, 0xD8, 0xFF]))
    }

    let result = try await service.indexDirectory(at: folder)
    expect(result.added).to(haveCount(3))
  }
}
