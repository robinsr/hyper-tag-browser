// created on 12/27/25 by robinsr

import Foundation
import GRDB
import Testing
import Nimble
import CustomDump

@testable import HyperTagBrowser



@Suite("GRDBIndexerService : GRDBTagAssociations", .serialized, .tags(.indexer, .tagRecord))
struct GRDBTagAssociationsTest {
  
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
      .to(containElementSatisfying { result in
        result.contentId.oneOf(eateryIds) && result.tagId.oneOf(foodIds)
      })
    }
  }
  
    //
    // MARK: - tag (associate tags)
    //
  
  @Suite(".tag")
  struct AddTagTests {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".tag(_:on:) - Add tag to content")
    func test_add_tag_to_content() async throws {
      let newSideDish: FilteringTag = .tag("PotatoSalad")
      let bbqJoint = Eatery.bbq
      
      let beforeAdd = try await service.getTagRecords(for: bbqJoint.id)
      let indxTagRecords = try await service.tag(newSideDish, on: [bbqJoint.id])
      let afterAdd = try await service.getTagRecords(for: bbqJoint.id)
      
      let newTag = afterAdd.first { $0.asFilter == newSideDish }
      
      await expect(newTag)
        .toNot(beNil())
        .to(map(\.asFilter, equal(newSideDish)))
      
      expect(indxTagRecords)
        .toNot(beNil())
      
      expect(indxTagRecords.map(\.contentId)).to(allPass { contentId in
        contentId == bbqJoint.id
      })
      
      expect(indxTagRecords.map(\.tagId)).to(allPass { tagId in
        tagId == newTag?.id
      })
      
      expect(afterAdd)
        .to(haveCount(beforeAdd.count + 1), description: "after adding a tag count to increase by 1")
      
      let expected: [FilteringTag] = [Food.chicken, Food.pie].map(\.asFilter) + [newSideDish]
      
      expect(expected).to(
        allPass { tag in
          afterAdd.contains(where: { $0.asFilter == tag })
        }
      )
    }
  }
  
    //
    // MARK: - setTags
    //
  
  @Suite(".setTags")
  struct SetTagsTests {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".setTags(_:on:) - Overwrites previous tag associations for content")
    func test_replace_tags_for_content() async throws {
      let newBakedGoods: [FilteringTag] = [.tag("danish"), .tag("tart"), .tag("muffin")]
      
      await expect {
        try await service.setTags(newBakedGoods, on: Eatery.bakery.id)
      }
      .to(haveCount(newBakedGoods.count))
      
      let tags = try await service.getTagRecords(for: Eatery.bakery.id)
      
      expect(tags).to(haveCount(newBakedGoods.count))
      
      expect(newBakedGoods)
        .to(allPass({ filter in
          tags.contains { $0.asFilter == filter }
        }))
    }
    
    @Test(".setTags(_:on:) - Overwrites previous tag associations for multiple contentIds")
    func test_replace_tags_for_many_content() async throws {
      let newTags: [FilteringTag] = [.tag("danish"), .tag("tart"), .tag("muffin")]
      let content = [Eatery.bakery, Eatery.coffeeshop]
      
      await expect {
        try await service.setTags(newTags, on: content.map(\.id))
      }
      .to(haveCount(newTags.count * 2))
      
      await expect {
        try await service.getTagRecords(for: newTags)
      }
      .to(haveCount(newTags.count))
    }
    
    @Test(".setTags(adding:removing:on:) - Modify tags")
    func test_modify_tags_for_content() async throws {

      let newSupplies: [FilteringTag] = [.tag("napkins"), .tag("straws")]
      let recalledItems: [FilteringTag] = [Food.chicken, .porkchop].map(\.asFilter)
      
      let eateriesWithRecalledItems = Eatery.allCases.filter { $0.foods.contains(any: [.chicken, .porkchop]) }
      
      // let nonRecalledOfferings: [FilteringTag] = Eatery.allCases
      //   .flatMap(\.foods)
      //   .map(\.asFilter)
      //   .reject(where: { $0.oneOf(recalledItems) })

      let (_,removed) = try await service.setTags(adding: newSupplies, removing: recalledItems, on: eateryIds)
      
      await expect(Eatery.allCases).to(allPass { eatery in
        let tags = try await service.getTagRecords(for: eatery.id)
        let expecting = eatery.foods.asFilters.reject(where: recalledItems.contains) + newSupplies
        
        expect(tags.map(\.asFilter))
          .to(haveCount(expecting.count), description: "tags for \(eatery.rawValue) to match expected count")
          .to(contain(expecting), description: "tags for \(eatery.rawValue) to match expected tags")
        
        return true
      })
      
      expect(removed)
        .to(haveCount(recalledItems.count * eateriesWithRecalledItems.count),
            description: "removed IndexTagRecords to equal number of eateries with recalled items")

      await expect {
        try await service.getTagRecord(for: Food.chicken.asFilter)
      }
      .to(beNil(), description: "unsed tag \(Food.chicken.asFilter) to be removed")

      await expect {
        try await service.getTagRecord(for: Food.porkchop.asFilter)
      }
      .to(beNil(), description: "unsed tag \(Food.porkchop.asFilter) to be removed")
    }
  }
  
    //
    // MARK: - untag
    //
  
  @Suite("untag")
  struct UntagTests {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    
    @Test(".untag(_:scope:) - Remove a tag entirely (no content associations)")
    func test_remove_tag_with_value() async throws {
      await expect {
        try await service.untag(Food.chicken.asFilter, scope: .all)
      }
      .to(equal(2), description: "tag associations removed")

      await expect {
        try await service.getTagRecord(for: Food.chicken.asFilter)
      }
      .to(beNil(), description: "TagRecord '\(Food.chicken)' not removed")
    }
    
    
    @Test(".untag(_:scope:) - Throws error for non-existent tag")
    func test_remove_tag_with_value_throws() async throws {
      await expect {
        try await service.untag(.tag("Zebra"), scope: .all)
      }
      .to(throwError(), description: "Error thrown for non-existent tag")
    }
    
    @MainActor
    @Test(".untag(_:matching:) - Remove tag from content matching query parameters")
    func test_remove_tag_with_value_matching() async throws {
      let hasDonuts = try await service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonuts)
        .toNot(beNil())
        .to(contain([
          Eatery.bakery.id,
          Eatery.coffeeshop.id
        ]))
      
      let filter = IndxRequestParams(
        root: URL.temporaryDirectory.filepath,
        visibility: .hidden
      )
      
      let removed = try await service.untag(Food.donuts.asFilter, matching: filter)
      
      expect(removed)
        .to(equal(1), description: "tag associations removed")
      
      let hasDonutsNow = try await service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonutsNow)
        .toNot(beNil())
        .to(contain([
          Eatery.bakery.id
        ]))
    }
    
    @MainActor
    @Test(".untag(_:from:) - Remove tag from content with IDs")
    func test_remove_tag_from_content() async throws {
      let hasDonuts = try await service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonuts)
        .toNot(beNil())
        .to(contain([
          Eatery.bakery.id,
          Eatery.coffeeshop.id
        ]))
      
      let removed = try await service.untag(Food.donuts.asFilter, from: [Eatery.bakery.id])

      expect(removed)
        .to(equal(1), description: "tag associations removed")
      
      let hasDonutsNow = try await service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonutsNow)
        .toNot(beNil())
        .to(contain([
          Eatery.coffeeshop.id
        ]))
    }
    

    @Test(".untag(_:scope:) - Removes associations and TagRecord when no associations remain")
    func test_remove_tag_if_unused() async throws {
      var tagCases = Foods.allFoods

      while !tagCases.isEmpty {
        guard let tag = tagCases.popLast() else {
//          tagCases.removeAll()
          break
        }
        
        let deleteCount = try await service.untag(tag.asFilter, scope: .all)
        
        expect(deleteCount).to(beGreaterThan(0))
      }
      
      await expect {
        try await service.getContentAssociations(tagId: foodIds)
      }
      .to(beEmpty(), description: "remaining tag associations")
      
      
      
      await expect(tagCases)
        .to(allPass({ tag in
          let tagRecord = try await service.getTagRecord(for: tag.asFilter)
          return tagRecord == nil
        }))
    }
    

    @Test(".untag(_:from:) - Does not remove tag with associations")
    func test_remove_tag_if_unused_with_value_not_removed() async throws {
      
      let contentItem = Eatery.bakery
      let filterTag = Food.donuts.asFilter
      let filterTagId = Food.donuts.id
      
      await expect {
        try await service.untag(filterTag, from: [contentItem.id])
      }
      .to(equal(1), description: "tag associations removed")

      await expect {
        try await service.getTagRecord(for: filterTag)
      }
      .toNot(beNil())
      .to(map(\.id, equal(Food.donuts.id)))

      await expect {
        try await service.getContentAssociations(tagId: Food.donuts.id)
      }
      .to(haveCount(1), description: "tag associations remaining")
    }
  }
  
    // MARK: - renameTag
  
  @Suite("renameTag")
  struct RenameTagTests {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    let applePie: FilteringTag = .tag("apple pie")
    

    @Test(".renameTag(_:to:) - Rename tag")
    func test_rename_tag_with_value_to() async throws {
      let hasDonuts = try await service.getContentIdAssociations(forTag: Food.donuts.id)

      let (renamed, tagitems) = try await service.renameTag(Food.donuts.asFilter, to: .tag("danish"))
      
//      expect(renamed)
//        .to(map(\.value, equal("danish")))
//        .to(map(\.rawValue, equal(.tag)))
//        .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")

      expect(tagitems)
        .to(haveCount(hasDonuts.count), description: "number of tag associations updated")
      
      await expect {
        try await service.getTagRecord(for: .tag("danish"))
      }
      .toNot(beNil(), description: "post-rename fetched tag")
      .to(equal(renamed), description: "matches tag returned from renameTag")
      .to(map(\.asFilter, equal(.tag("danish"))), description: "tag renamed to 'danish'")
      .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")
    }
    

    @Test(".renameTag(_:to:) - Apply new tag label")
    func test_rename_tag_change_tag_label() async throws {
      let hasDonuts = try await service.getContentIdAssociations(forTag: Food.donuts.id)

      let (renamed, tagitems) = try await service.renameTag(Food.donuts.asFilter, to: .artist("donuts"))
      
//      expect(renamed)
//        .to(map(\.value, equal("donuts")))
//        .to(map(\.rawValue, equal(.artist)))
//        .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")

      expect(tagitems)
        .to(haveCount(hasDonuts.count), description: "number of tag associations updated")
      
      await expect {
        try await service.getTagRecord(for: .artist("donuts"))
      }
      .toNot(beNil(), description: "post-rename fetched tag")
      .to(equal(renamed), description: "matches tag returned from renameTag")
      .to(map(\.asFilter, equal(.artist("donuts"))), description: "tag re-labeled tag to match artist|donuts'")
      .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")
    }
    

    @Test(".renameTag(_:to:for:) - Rename tag for content IDs")
    func test_rename_tag_with_value_to_for() async throws {
      
      let (renamed, tagitems) = try await service.renameTag(Food.pie.asFilter, to: applePie, for: [Eatery.diner.id])

      await expect(renamed)
        .toNot(beNil())
        .to(beAKindOf(TagRecord.self))
        .to(map(\.asFilter, equal(applePie)))
      
      
      expect(tagitems).to(haveCount(1), description: "updated associations")
      
      await expect {
        try await service.getTagRecord(for: applePie)
      }
      .notTo(beNil())
      .to(beAKindOf(TagRecord.self))
      .to(map(\.asFilter, equal(applePie)))
      
      await expect {
        try await service.getTagRecord(for: Food.pie.asFilter)
      }
      .notTo(beNil())
      .to(beAKindOf(TagRecord.self))
      .to(map(\.asFilter, equal(Food.pie.asFilter)))
    }
    
    
      /// Rename tag "pie" to "Apple Pie" but only for items that also have "waffles"
      /// Pie is on 3 items: bakery, bbq, and diner, and only one of those has waffles: the classic diner
    @Test(".renameTag(_:to:matching:) - Rename tag for content matching query parameters")
    func test_rename_tag_with_value_to_matching() async throws {
      let params = IndxRequestParams(
        root: URL.temporaryDirectory.filepath,
        tagsMatching: FilteringTagMultiParam([Food.waffles.asFilter.asInclusive], operator: .and)
      )

      let (renamed, tagitems) = try await service.renameTag(Food.pie.asFilter, to: applePie, matching: params)
      
      await expect(renamed)
        .toNot(beNil())
        .to(map(\.asFilter, equal(applePie)))
      
      expect(tagitems)
        .to(containElementSatisfying({ $0.contentId == Eatery.diner.id }))
        .to(haveCount(1), description: "only the diner has both waffles and pie")
      
      let itemsWithPlainPie = try await service.getContentAssociations(tagId: Food.pie.id)

      expect(itemsWithPlainPie)
        .to(haveCount(2), description: "bakery and bbq dont serve waffles, should still have original pie")
        .to(containElementSatisfying({ $0.contentId == Eatery.bakery.id }))
        .to(containElementSatisfying({ $0.contentId == Eatery.bbq.id }))
    }
  }
  
    //
    // MARK: - consolidateTag
    //
  
  @Suite(".consolidateTag")
  struct ConsolidateTagsTests {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    let breakfast: FilteringTag = .tag("breakfast")
    let dinner: FilteringTag = .tag("dinner")
    let dessert: FilteringTag = .tag("dessert")
    
//    @MainActor
//    @Test(".consolidateTag(_:into:) - Consolidate tag", .disabled("Disabled for project migration"))
//    func test_consolidate_tag_with_value_into() async throws {
//
//      _ = try await service.createTagRecord(for: breakfast)
//      _ = try await service.createTagRecord(for: dinner)
//      _ = try await service.createTagRecord(for: dessert)
//
//      for item in [Food.donuts, .pancakes, .waffles] {
//        _ = try await service.consolidateTag(item.asFilter, into: breakfast)
//      }
//
//      for item in [Food.chicken, .porkchop, .soup] {
//        _ = try await service.consolidateTag(item.asFilter, into: dinner)
//      }
//
//      for item in [Food.cake, .cookies, .pie] {
//        _ = try await service.consolidateTag(item.asFilter, into: dessert)
//      }
//
//
//      await expect(try await service.getTagRecord(for: Eatery.bakery.id))
//        .toEventually(haveCount(2), description: "bakery items")
//        .toEventually(allPass { tagitem in
//            [breakfast, dessert].contains(tagitem.asFilter)
//        })
//
//      await expect(try await service.getTagRecord(for: Eatery.bbq.id))
//        .toEventually(haveCount(2), description: "bakery items")
//        .toEventually(allPass { tagitem in
//            [dinner, dessert].contains(tagitem.asFilter)
//        })
//
//      await expect(try await service.getTagRecord(for: Eatery.coffeeshop.id))
//        .toEventually(haveCount(2), description: "bakery items")
//        .toEventually(allPass { tagitem in
//            [breakfast, dessert].contains(tagitem.asFilter)
//        })
//
//      await expect(try await service.getTagRecord(for: Eatery.diner.id))
//        .toEventually(haveCount(3), description: "bakery items")
//        .toEventually(allPass { tagitem in
//            [breakfast, dinner, dessert].contains(tagitem.asFilter)
//        })
//
//      let _ = try await queue.read { db in
//        try db.dumpRequest(IndexTagValueRecord.all().order(Column("contentId").desc), format: .debug())
//      }
//    }
    

    @Test(".consolidateTag(_:into:) - Consolidate tag into non-existent tag")
    func test_consolidate_tag_with_value_into_non_existent() async throws {
      let brunch: FilteringTag = .tag("brunch")
      
      await expect {
        try await service.consolidateTag(Food.chicken.asFilter, into: brunch)
      }
      .to(throwError { err in
        expect(err).to(matchError(IndexerServiceError.InvalidParameter(brunch.rawValue)))
      })
    }
    

    @Test(".consolidateTag(_:into:) - Consolidate tag into itself")
    func test_consolidate_tag_with_value_into_itself() async throws {
      let tagitems = try await service.consolidateTag(Food.donuts.asFilter, into: Food.donuts.asFilter)
      
      expect(tagitems)
        .to(haveCount(2), description: "tag items affected by consolidated")

      await expect {
        try await service.getTagRecords(for: Eatery.bakery.id)
      }
      .toEventually(haveCount(Eatery.bakery.foods.count), description: "bakery goods")
      .toEventually(allPass { tagitem in
        Eatery.bakery.foods.map(\.id).contains(tagitem.id)
      })

      await expect {
        try await service.getTagRecords(for: Eatery.coffeeshop.id)
      }
      .toEventually(haveCount(Eatery.coffeeshop.foods.count), description: "coffeeshop items")
      .toEventually(allPass { tagitem in
        Eatery.coffeeshop.foods.map(\.id).contains(tagitem.id)
      })
    }
  }
}
