// created on 12/12/24 by robinsr

import Foundation
import GRDB
import Testing
import Nimble
import CustomDump

@testable import HyperTagBrowser



extension GRDBIndexerServiceTests {
  
  
  @Suite("IndexAccess", .serialized, .tags(.indexer, .indexRecord))
  struct GRDBIndexesTest {
    
    private typealias Indx = IndexRecordFixture
    private typealias Tags = TagRecordFixture
    private typealias Tagged = IndexTagRecordFixture
    
    
    
    @Suite("getIndex")
    struct GetIndexTests {
      
      var service: GRDBIndexService
      var queue: DatabaseQueue
      
      init() async throws {
        (service,queue) = try await TestSupportDB.setupDB()
      }
      
      
      @Test(".getIndex(withId:)")
      func test_grdbindexer_getindex_getindex_withid() async throws {
        let fixture = IndexRecordFixture.withId(Indx.ids.first!)!
        
        let contentId = try fixture.contentId(for: "id")
        let name = try fixture.string(for: "name")
        let location = try fixture.filepath(for: "location")
        let filepath = location.appending(name)
        
        guard let index = try await service.getIndex(withId: contentId) else {
          fail("Index with id \(contentId) not found")
          return
        }
        
        customDump(index, name: "IndexRecord")
        
        expect(index).toNot(beNil())
        expect(index.contentId).to(equal(contentId))
        expect(index.name).to(equal(name))
        expect(index.filepath).to(equal(filepath))
        expect(index.exists).to(beFalse())
        expect(index.isIndexed).to(beTrue())
      }
    }
    
    
    @Suite("getIndexes")
    struct GetIndexesFromParams {
      var service: GRDBIndexService
      var queue: DatabaseQueue
      
      init() async throws {
        (service,queue) = try await TestSupportDB.setupDB()
      }
      
      @Test(".getIndexes(matching:) - visible")
      func test_get_indexes_params_visible() async throws {
        let params = IndxRequestParams(
          root: URL.temporaryDirectory.filepath,
          mode: .recursive(),
          visibility: .normal)
        
        let expected: [Indx.Cases] = [.bakery, .bbq, .diner]
        
        
        await expect {
          try await service.getIndexes(matching: params)
        }
        .toNot(beEmpty())
        .to(haveCount(expected.count))
        .to(map(\.ids, equalDiff(expected.map(\.id)))) // (expected.map(\.id))))
      }
      

      @Test(".getIndexes(matching:) - hidden")
      func test_get_indexes_params_hidden() async throws {
        let params = IndxRequestParams(
          root: URL.temporaryDirectory.filepath,
          mode: .recursive(),
          visibility: .hidden)
        
        await expect {
          try await service.getIndexes(matching: params)
        }
        .toNot(beEmpty())
        .to(haveCount(1))
        .to(map(\.ids, equal([Indx.Cases.coffeeshop.id])))
      }
      
      
      @Test(".getIndexes(matching:) - any")
      func test_get_indexes_params_visibility_any() async throws {
        let allContentIds = IndexRecordFixture.Cases.allCases.map(\.id)
        
        let params = IndxRequestParams(
          root: URL.temporaryDirectory.filepath,
          mode: .recursive(),
          visibility: .any,
          options: [], // Remove `.fileMustExist` contraint
        )
        
        await expect {
          try await service.getIndexes(matching: params)
        }
        .toNot(beEmpty())
        .to(haveCount(Indx.Cases.allCases.count))
        .to(allPass { indx in
          allContentIds.contains(indx.contentId)
        })
      }
      
      @Test(".getIndexes(matching:) - video")
      func test_get_indexes_params_type_video() async throws {
        
        let params = IndxRequestParams(
          root: URL.temporaryDirectory.filepath,
          mode: .recursive(),
          types: [.video],
          visibility: .any,
          options: [], // Remove `.fileMustExist` contraint
        )
        
        var expectedResults = [
          IndexRecordFixture.Cases.diner,
          IndexRecordFixture.Cases.coffeeshop,
        ]
        
        await expect {
          try await service.getIndexes(matching: params)
        }
        .toNot(beEmpty())
        .to(haveCount(expectedResults.count))
        .to(allPass { indx in
          expectedResults.map(\.id).contains(indx.contentId)
        })
      }
      
      
      @Test(".getIndexes(matching:) - FilteringTagMultiParam.or")
      func test_get_indexes_params_tagged_joined_or() async throws {
        let tags = Tags.bbqGoods.asFilters.map(\.asInclusive)
        
        let tagsMatching = FilteringTagMultiParam(tags, operator: .or)
        
        let params = IndxRequestParams(
          root: URL.temporaryDirectory.filepath,
          mode: .recursive(),
          tagsMatching: tagsMatching,
          visibility: .any,
          options: [], // Remove `.fileMustExist` contraint
        )
        
        customDump(params, name: "PARAMS .getIndexes(matching:) - FilteringTagMultiParam.or")
        
        let expectedMatchingIndexes = [
          Indx.Cases.bakery,
          Indx.Cases.bbq,
          Indx.Cases.diner
        ]
        
        await expect {
          let result = try await service.getIndexes(matching: params)
          
          customDump(result, name: "RESULT .getIndexes(matching:) - FilteringTagMultiParam.or")
          
          return result
        }
        .to(haveCount(expectedMatchingIndexes.count))
        .to(allPass { indx in
          expectedMatchingIndexes.map(\.id).contains(indx.contentId)
        })
      }
      
      
      @MainActor
      @Test(".getIndexes(matching:) - FilteringTagMultiParam.and")
      func test_get_indexes_params_tagged_joined_and() async throws {
        let tagsMatching = [
          Tags.Cases.porkchop.asFilter.asInclusive,
          Tags.Cases.chicken.asFilter.asInclusive,
        ]
        
        let params = IndxRequestParams(
          root: URL.temporaryDirectory.filepath,
          mode: .recursive(),
          tagsMatching: FilteringTagMultiParam(tagsMatching, operator: .and),
          options: [], // Remove `.fileMustExist` contraint
        )
        
        let bbqGoodsFoundAt = [
          Indx.Cases.bbq.id,
          Indx.Cases.diner.id
        ]
        
        let results = try await service.getIndexes(matching: params)
        
        expect(results.map(\.contentId).asSet)
          .to(equalDiff(
            Indx.records.map(\.contentId).filter {
              bbqGoodsFoundAt.contains($0)
            }.asSet
          ))
      }
    }
    
    
    @Suite("getContentItems")
    struct GetContentItemsTests {
      
      var service: GRDBIndexService
      var queue: DatabaseQueue
      
      init() async throws {
        (service,queue) = try await TestSupportDB.setupDB()
      }
      
      @Test(".getContentItems(withId:)")
      func test_get_index_info_for_ids() async throws {
        let ids = Indx.records.map(\.contentId)
        
        await expect {
          try await service.getContentItems(withId: ids)
        }
        .toNot(beEmpty())
        .to(haveCount(ids.count))
          //    .to(map(\.contentId, equalDiff(ids)))
      }
    }
    
    @Suite("getContentItem")
    struct GetContentItemTests {
      
      var service: GRDBIndexService
      var queue: DatabaseQueue
      
      init() async throws {
        (service,queue) = try await TestSupportDB.setupDB()
      }
      
      @Test("getContentItem(withId:)")
      func test_get_index_info() async throws {
        guard let result = try await service.getContentItem(withId: Indx.Cases.bakery.id) else {
          fail("IndexInfo with id \(Indx.Cases.bakery.id.value) not found")
          return
        }
        
        let bakeryIds = Tags.bakeryGoods.identifiers
        
        let contentId = result.id
        let indexrecrod = result.index
        let indxId = result.index.contentId
        let tagCount = result.tagCount
        let tagValues = result.tagValues
        let tagIds = result.tagValues.map(\.id)
        
        expect(result).notTo(beNil())
        
        expect(contentId).to(equal(Indx.Cases.bakery.id))
        
        expect(indexrecrod).notTo(beNil())
        
        expect(indxId).to(equal(Indx.Cases.bakery.id))
        
        expect(tagValues.count).to(equal(4))
        
        expect(tagIds).to(allPass { tagId in
          bakeryIds.contains(tagId)
        })
      }
    }
  }
}
