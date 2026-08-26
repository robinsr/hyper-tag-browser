// created on 8/26/26 by robinsr

import Foundation
import GRDB
import GRDBQuery
import System
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("CountIndexesRequest", .serialized, .tags(.indexer, .indexRecord))
struct CountIndexesRequestTest {

  private typealias Indx = IndexRecordFixture
  private typealias Tags = TagRecordFixture

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  @Test("returns 0 when parameters is nil")
  func test_nil_parameters_returns_zero() async throws {
    let request = CountIndexesRequest(parameters: nil)

    let count = try await queue.read { db in try request.fetch(db) }

    expect(count).to(equal(0))
  }

  @Test("count with visibility .any equals total fixture record count")
  func test_count_all() async throws {
    let request = CountIndexesRequest(parameters: IndxRequestParams(
      root: URL.temporaryDirectory.filepath,
      mode: .recursive(),
      visibility: .any,
      options: [] // Remove `.fileMustExist` constraint
    ))

    let count = try await queue.read { db in try request.fetch(db) }

    expect(count).to(equal(Indx.Cases.allCases.count))
  }

  @Test("count with visibility .normal excludes hidden records")
  func test_count_visible_only() async throws {
    let request = CountIndexesRequest(parameters: IndxRequestParams(
      root: URL.temporaryDirectory.filepath,
      mode: .recursive(),
      visibility: .normal,
      options: [] // Remove `.fileMustExist` constraint
    ))

    let count = try await queue.read { db in try request.fetch(db) }

    // bakery, bbq, diner are normal; coffeeshop is hidden
    let expectedNormalCount = Indx.Cases.allCases.filter { c in
      c != .coffeeshop
    }.count

    expect(count).to(equal(expectedNormalCount))
    expect(count).to(beLessThan(Indx.Cases.allCases.count))
  }

  @Test("count with visibility .hidden returns only hidden records")
  func test_count_hidden_only() async throws {
    let request = CountIndexesRequest(parameters: IndxRequestParams(
      root: URL.temporaryDirectory.filepath,
      mode: .recursive(),
      visibility: .hidden,
      options: [] // Remove `.fileMustExist` constraint
    ))

    let count = try await queue.read { db in try request.fetch(db) }

    // Only coffeeshop has visibility: .hidden
    expect(count).to(equal(1))
  }

  @Test("count with type .video returns only video records")
  func test_count_video_type() async throws {
    let request = CountIndexesRequest(parameters: IndxRequestParams(
      root: URL.temporaryDirectory.filepath,
      mode: .recursive(),
      types: [.video],
      visibility: .any,
      options: [] // Remove `.fileMustExist` constraint
    ))

    let count = try await queue.read { db in try request.fetch(db) }

    // diner and coffeeshop are mpeg4Movie (video)
    expect(count).to(equal(2))
  }

  @Test("count with type .images returns only image records")
  func test_count_image_type() async throws {
    let request = CountIndexesRequest(parameters: IndxRequestParams(
      root: URL.temporaryDirectory.filepath,
      mode: .recursive(),
      types: [.images],
      visibility: .any,
      options: [] // Remove `.fileMustExist` constraint
    ))

    let count = try await queue.read { db in try request.fetch(db) }

    // bakery and bbq are JPEG (image)
    expect(count).to(equal(2))
  }

  @Test("count with mode .immediate limits to the given root directory")
  func test_count_immediate_mode() async throws {
    // jpeg_files and video_files are different subdirectories;
    // .immediate mode rooted at temporaryDirectory should not match
    // records in subdirectories
    let request = CountIndexesRequest(parameters: IndxRequestParams(
      root: URL.temporaryDirectory.filepath,
      mode: .immediate(),
      visibility: .any,
      options: [] // Remove `.fileMustExist` constraint
    ))

    let count = try await queue.read { db in try request.fetch(db) }

    // All fixtures are stored in subdirectories (jpeg_files, video_files),
    // so an immediate (non-recursive) query at the root returns 0
    expect(count).to(equal(0))
  }

  @Test("count excludes results outside the specified root")
  func test_count_unrelated_root_returns_zero() async throws {
    let unrelatedRoot = FilePath("/some/unrelated/path")
    let request = CountIndexesRequest(parameters: IndxRequestParams(
      root: unrelatedRoot,
      mode: .recursive(),
      visibility: .any,
      options: [] // Remove `.fileMustExist` constraint
    ))

    let count = try await queue.read { db in try request.fetch(db) }

    expect(count).to(equal(0))
  }
}
