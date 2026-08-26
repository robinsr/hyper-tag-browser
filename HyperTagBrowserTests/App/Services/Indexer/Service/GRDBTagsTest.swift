// created on 12/11/24 by robinsr

import Foundation
import GRDB
import Testing
import Nimble
import CustomDump

@testable import HyperTagBrowser



@Suite("GRDBIndexerService : GRDBTags", .serialized, .tags(.indexer, .tagRecord))
struct GRDBTagsTest {
  
  typealias Indx = IndexRecordFixture
  typealias Tags = TagRecordFixture
  typealias Tagged = IndexTagRecordFixture
  
  typealias Eateries = IndexRecordFixture
  typealias Eatery = IndexRecordFixture.Cases
  
  static let eateryIds: [ContentId] = Eateries.records.map(\.contentId)
  
  typealias Foods = TagRecordFixture
  typealias Food = TagRecordFixture.Cases
  
  static let foodFilters: [FilteringTag] = Foods.allFoods.map(\.asFilter)
  static let foodTags: [TagRecord] = Foods.records.filter { $0.tagType == .tag }
  static let foodIds: [TagRecord.ID] = Foods.records.filter { $0.tagType == .tag }.map(\.id)
  
  
  static let offerings: [IndexTagRecord] = IndexTagRecordFixture.records
  
  var service: GRDBIndexService
  var queue: DatabaseQueue
  
  init() async throws {
    (service,queue) = try await TestSupportDB.setupDB()
  }
  
    // MARK: - createTag
  
  @Suite(".createTag")
  struct CreateTag {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    
    @Test(".createTagRecord(for:) - Creates a TagRecord for a FilteringTag")
    func test_create_tag_with_value() async throws {
      await expect {
        try await service.createTagRecord(for: .tag("create-tag-test"))
      }
      .to(map(\.tagValue, equal("create-tag-test")))
      .to(map(\.asFilter, equal(.tag("create-tag-test"))))
    }
  }
  
    // MARK: - tagExists
  
  @Suite(".tagExists")
  struct TagExists {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    
    @Test(".tagExists(_filter:) - Check if TagRecord exists by FilteringTag")
    func test_tag_exists() async throws {
      
      foodFilters.forEach { filter in
        Task {
          let result = try await service.tagRecordExists(for: filter)
          
          expect(result)
            .to(beTrue(), description: "tag '\(filter)' exists")
        }
      }
      
      await expect {
        try await service.tagRecordExists(for: .tag("not-a-tag"))
      }
      .to(beFalse(), description: "tag 'not-a-tag' to not exist")
    }
  }
  
  
    // MARK: - getTag
  
  @Suite(".getTagRecord")
  struct GetTags {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    
    @Test(".getTagRecord(for: _filter:) - Retrieve TagRecord by FilteringTag")
    func test_get_tag_with_value() async throws {
      await expect {
        try await service.getTagRecords(for: foodFilters)
      }
      .to(haveCount(foodFilters.count),
          description: "returned TagResults should match number of test tags")
    }
    
    
    @Test(".getTagRecord(for: forContent:) - Retrieve TagRecord by ContentId")
    func test_get_tags_for_content() async throws {
      
      let bakery: Eatery = .bakery
      let bakedGoods: [Food] = [.cake, .cookies, .donuts, .pie]
      let bakedFilters = bakedGoods.asFilters
      
      await expect {
        try await service.getTagRecords(for: bakery.id)
      }
      .toNot(beNil())
      .to(haveCount(bakedGoods.count), description: "bakery items")
      .to(
        allPass { tag in
          bakedFilters.contains(tag.asFilter)
        }
      )
    }
  }
  
  
    // MARK: - getContentAssociations
  
  @Suite(".getContentAssociations")
  struct GetContentAssociations {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    
    @Test(".getContentAssociations(tagId:) - Retrieve IndexTagRecord by ContentId")
    func test_get_content_associations() async throws {
      await expect {
        try await service.getContentAssociations(tagId: foodIds)
      }
      .to(haveCount(offerings.count), description: "returned associations to match expected count")
      .to(
        containElementSatisfying { result in
          result.contentId.oneOf(eateryIds) && result.tagId.oneOf(foodIds)
        }
      )
    }
  }
  
  
    // MARK: - findOrCreateTag
  
  @Suite(".findOrCreateTag")
  struct FindOrCreateTag {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    
    @Test(".findOrCreateTagRecords(for: ) - Fetches or creates TagRecord for FilteringTag")
    func test_find_or_create_tag_for_values() async throws {
      let filters: [FilteringTag] = Foods.fruitTags.first(3).asArray
      
      await expect {
        try await service.findOrCreateTagRecords(for: filters)
      }
      .to(haveCount(3), description: "3 tags found or created")
      .to(containElementSatisfying({ $0.asFilter == filters[0] }))
      .to(containElementSatisfying({ $0.asFilter == filters[1] }))
      .to(containElementSatisfying({ $0.asFilter == filters[2] }))
    }
  }
}
