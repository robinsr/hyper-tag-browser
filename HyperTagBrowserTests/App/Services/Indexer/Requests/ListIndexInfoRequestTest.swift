// created on 12/16/24 by robinsr

import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble
import CustomDump

@testable import TaggedFileBrowser


@MainActor
@Suite("GRDBIndexerService : ListIndexInfoRequest", .serialized, .tags(.indexer))
struct ListIndexInfoRequestTest {
  
  typealias Indx = IndexRecordFixture
  typealias Tags = TagRecordFixture
  typealias Tagged = IndexTagRecordFixture
  typealias fns = TestSupportFns
  
  var service: GRDBIndexService
  var queue: DatabaseQueue
  
  init() async throws {
    (service,queue) = try await TestSupportDB.setupDB()
  }
  
  @Test("ListIndexInfoRequest should return all IndexRecords",
    .disabled("GRDBQuery requires a SwiftUI context. Need to research how to test this."))
  func testListIndexInfoRequest() async {
    let request = ListIndexInfoRequest()
    
    let query = Query(request)
    
    query.update()
    
    expect(query.wrappedValue.count) == 3
  }
}
