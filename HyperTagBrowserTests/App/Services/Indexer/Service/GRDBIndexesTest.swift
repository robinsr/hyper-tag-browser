// created on 12/12/24 by robinsr

import Foundation
import GRDB
import Testing
import Nimble
import CustomDump

@testable import TaggedFileBrowser

/**
 Protocol methods to test:
 
 - [x] getIndex(withId:) throws -> IndexRecord?
 - [ ] getIndexes(matching:) throws -> [IndexRecord]
 - [x] getIndexInfo(withId:) throws -> IndexInfoRecord?
 - [ ] getIndexInfo(atLocation:) throws -> [IndexInfoRecord]
 - [ ] getIndexInfo(matching:) throws -> [IndexInfoRecord]
 - [ ] getLocations() throws -> [URL]
 - [ ] updateIndex(withId:name:) throws -> Int
 - [ ] updateIndex(withId:moveTo:) throws -> RenameTask
 - [ ] updateIndex(withId:moveTo:) throws -> [RenameTask]
 - [ ] updateIndex(withId:visibility:) throws -> Int
 */
@Suite("GRDBIndexerService : GRDBIndexes", .serialized, .tags(.indexer, .indexRecord))
struct GRDBIndexesTest {
  
  private typealias Indx = IndexRecordFixture
  private typealias Tags = TagRecordFixture
  private typealias Tagged = IndexTagRecordFixture
  private typealias fns = TestSupportFns
  
  var service: GRDBIndexService
  var queue: DatabaseQueue
  
  init() async throws {
    (service,queue) = try await TestSupportDB.setupDB()
  }
  
  @Test(".getIndex(withId:) - Index exists")
  func test_index_exists() throws {
    let fixtr = Indx.withId(Indx.ids.first!)!
    
    let contentId = fixtr.contentId("id")
    
    guard let index = try service.getIndex(withId: contentId) else {
      fail("Index with id \(contentId) not found")
      return
    }
    
    customDump(index, name: "IndexRecord")

    expect(index).toNot(beNil())
    expect(index.contentId).to(equal(contentId))
    expect(index.name).to(equal(fixtr.stringVal("name")))
    expect(index.location).to(equal(fixtr.urlVal("location")))
    
    expect(index.url)
      .to(equal(
        fixtr.urlVal("location")
          .appendingPathComponent(fixtr.stringVal("name"))
      ))
    
    expect(index.isIndexed).to(beTrue())
    
    
  }
  
  @Suite("getIndexes")
  struct GetIndexesFromParams {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test("matching: - visible files")
    func test_get_indexes_params_visible() throws {
      let params = IndxRequestParams(
        rootDir: URL.temporaryDirectory,
        mode: .recursive(uncached: true),
        types: .images,
        visibility: .normal)
      
      let expected: [Indx.Cases] = [.bakery, .bbq, .diner]
      
      expect(try service.getIndexes(matching: params))
        .toNot(beEmpty())
        .to(haveCount(expected.count))
        .to(map(\.ids, equalDiff(expected.map(\.id)))) // (expected.map(\.id))))
    }
    
    @Test("matching: - hidden files")
    func test_get_indexes_params_hidden() throws {
      let params = IndxRequestParams(
        rootDir: URL.temporaryDirectory,
        mode: .recursive(uncached: true),
        types: .images,
        visibility: .hidden)
      
      expect(try service.getIndexes(matching: params))
        .toNot(beEmpty())
        .to(haveCount(1))
        .to(map(\.ids, equal([Indx.Cases.coffeeshop.id])))
    }
    
    @Test("matching: - any visibility")
    func test_get_indexes_params_visibility_any() throws {
      let params = IndxRequestParams(
        rootDir: URL.temporaryDirectory,
        mode: .recursive(uncached: true),
        types: .images,
        visibility: .any)
      
      expect(try service.getIndexes(matching: params))
        .toNot(beEmpty())
        .to(haveCount(Indx.Cases.allCases.count))
        .to(map(\.ids, equal(Indx.Cases.allCases.map(\.id))))
    }
    
    @Test("matching: - any tag (SQL OR)")
    func test_get_indexes_params_tagged_joined_or() async throws {
      let params = IndxRequestParams(
        rootDir: URL.temporaryDirectory,
        mode: .recursive(uncached: true),
        types: .images,
        tags: Tags.bbqGoods.tagSet, // porkchop (bbq, diner), chicken (bbq, diner), pie (bbq, diner, and bakery)
        opr: .or,
        visibility: .any
      )
      
      let bbqGoodsFoundAt = [
        Indx.Cases.bakery.id,
        Indx.Cases.bbq.id,
        Indx.Cases.diner.id
      ]
      
      let results = try service.getIndexes(matching: params)
      
      expect(results.map(\.contentId).asSet)
        .to(equalDiff(
          Indx.records.map(\.contentId).filter {
            bbqGoodsFoundAt.contains($0)
          }.asSet
        ))
    }
    
    
    @Test("matching: - any tag (SQL OR)")
    func test_get_indexes_params_tagged_joined_and() async throws {
      let params = IndxRequestParams(
        rootDir: URL.temporaryDirectory,
        mode: .recursive(uncached: true),
        types: .images,
        tags: Array(
          uniqueElements: [
            .tag(Tags.Cases.porkchop.rawValue),
            .tag(Tags.Cases.chicken.rawValue),
          ]
        ),
        // porkchop (bbq, diner), chicken (bbq, diner), pie (bbq, diner, and bakery)
        opr: .and,
        visibility: .any
      )
      
      let bbqGoodsFoundAt = [
        Indx.Cases.bbq.id,
        Indx.Cases.diner.id
      ]
      
      let results = try service.getIndexes(matching: params)
      
      expect(results.map(\.contentId).asSet)
        .to(equalDiff(
          Indx.records.map(\.contentId).filter {
            bbqGoodsFoundAt.contains($0)
          }.asSet
        ))
    }
  }
  
  @Test("getIndexInfo(forIds:) - Get Index Info Records")
  func test_get_index_info_for_ids() throws {
    let ids = Indx.records.map(\.contentId)
    
    let results = try service.getIndexInfo(withId: ids)
    
    expect(results)
      .toNot(beEmpty())
      .to(haveCount(ids.count))
//      .to(map(\.contentId, equalDiff(ids)))
  }
  
  
  @Test("getIndexInfo(withId:) - Get Index Info Record")
  func test_get_index_info() throws {
    guard let result = try service.getIndexInfo(withId: Indx.Cases.bakery.id) else {
      fail("IndexInfo with id \(string: Indx.Cases.bakery.rawValue) not found")
      return
    }
    
    expect(result)
      .toNot(beNil())
      .to(map(\.contentId, equal(Indx.Cases.bakery.id)))
      .to(map(\.index, not(beNil())))
      .to(map(\.index.contentId, equal(Indx.Cases.bakery.id)))
      .to(map(\.tagCount, equal(4)))
      .to(map(\.tagValues, allPass { tagval in
        Tags.bakeryGoods.map(\.id).contains(tagval.tagId)
      }))
  }
}
