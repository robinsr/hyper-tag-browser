// created on 12/11/24 by robinsr

import Foundation
import GRDB
import Testing
import Nimble
import CustomDump

@testable import TaggedFileBrowser



@Suite("GRDBIndexerService : GRDBTags", .serialized, .tags(.indexer, .tagRecord))
struct GRDBTagsTest {
  
  typealias Indx = IndexRecordFixture
  typealias Tags = TagRecordFixture
  typealias Tagged = IndexTagRecordFixture
  typealias fns = TestSupportFns
  
  typealias Eateries = IndexRecordFixture
  typealias Eatery = IndexRecordFixture.Cases
  
  static let eateryIds: [ContentId] = Eateries.records.map(\.contentId)
  
  typealias Foods = TagRecordFixture
  typealias Food = TagRecordFixture.Cases
  
  static let foodFilters: [FilteringTag] = Foods.allFoods.map(\.asFilter)
  static let foodTags: [TagRecord] = Foods.records.filter { $0.label == .tag }
  static let foodIds: [TagRecord.ID] = Foods.records.filter { $0.label == .tag }.map(\.id)
  
  
  static let offerings: [IndexTagRecord] = IndexTagRecordFixture.records
  
  var service: GRDBIndexService
  var queue: DatabaseQueue
  
  init() async throws {
    (service,queue) = try await TestSupportDB.setupDB()
  }
  
  @Suite("temp")
  struct Temp {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB(.indexer_debugSqlStatements, .testing_verboselogs)
    }
    
    @Test("temp - print stuff", .tags(/*.only*/))
    func selection_prints_correctly() throws {
      let selection: [FilteringTag] = [.tag("a"), .tag("b"), .tag("c")]
      
      try queue.read { db in
        
        let request = TagRecord.all()
          .select(TagRecord.databaseSelection)
        
        let statement = try request.makePreparedRequest(db).statement
        
        print(statement)
        print(statement.arguments)
        
        
        try db.dumpRequest(request, format: TestSupportDB.debugDumpFormat)
      }
      
      
      expect(selection)
        .to(equal([.tag("a"), .tag("b"), .tag("c")]), description: "selection prints correctly")
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
    func test_tag_exists() throws {
      
      try foodFilters.forEach { filter in
        expect(try service.tagExists(filter))
          .to(beTrue(), description: "tag '\(filter)' exists")
      }
      
      expect(try service.tagExists(.tag("not-a-tag")))
        .to(beFalse(), description: "tag 'not-a-tag' to not exist")
    }
  }
  
  
    // MARK: - getTag
  
  @Suite(".getTag")
  struct GetTags {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".getTagRecord(for: _filter:) - Retrieve TagRecord by FilteringTag")
    func test_get_tag_with_value() throws {
      expect(try foodFilters.map(service.getTag))
        .to(haveCount(foodFilters.count),
            description: "returned TagResults should match number of test tags")
    }
    
    @Test(".getTagRecord(for: forContent:) - Retrieve TagRecord by ContentId")
    func test_get_tags_for_content() async throws {
      
      let bakery: Eatery = .bakery
      let bakedGoods: [Food] = [.cake, .cookies, .donuts, .pie]
      
      let getTagsResult = try service.getTags(forContent: bakery.id)
      
      expect(getTagsResult)
        .toNot(beNil())
        .to(haveCount(bakedGoods.count), description: "bakery items")

      expect(getTagsResult.map(\.asFilter))
        .to(contain(bakedGoods.map(\.asFilter)), description: "TagRecord bakery goods to match expected bakery goods")
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
      let results = try service.getContentAssociations(tagId: foodIds)
      
      expect(results)
        .to(haveCount(offerings.count), description: "returned associations to match expected count")
        .to(containElementSatisfying({ result in
          result.contentId.oneOf(eateryIds) && result.tagId.oneOf(foodIds)
        }))
    }
  }
  
  
    // MARK: - addTag
  
  @Suite(".addTag")
  struct AddTag {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".addTag(_:toContent:) - Add tag to content")
    func test_add_tag_to_content() async throws {
      let newSideDish: FilteringTag = .tag("PotatoSalad")
      let bbqJoint = Eatery.bbq
      
      let beforeAdd = try service.getTags(forContent: bbqJoint.id)
      let tagged = try service.associateTag(newSideDish, toContent: bbqJoint.id)
      let afterAdd = try service.getTags(forContent: bbqJoint.id)
      
      let newTag = afterAdd.first { $0.asFilter == newSideDish }
      
      expect(newTag)
        .toNot(beNil())
        .to(map(\.asFilter, equal(newSideDish)))
      
      expect(tagged)
        .toNot(beNil())
        .to(map(\.contentId, equal(bbqJoint.id)))
        .to(map(\.tagId, equal(newTag?.id)))
      
      expect(afterAdd)
        .to(haveCount(beforeAdd.count + 1), description: "after adding a tag count to increase by 1")
      
      let expected: [FilteringTag] = [Food.chicken, Food.pie].map(\.asFilter) + [newSideDish]
      
      expect(expected).to(allPass({ tag in
        afterAdd.contains(where: { $0.asFilter == tag })
      }))
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
      
      
      let tags: [TagRecord] = try service.findOrCreateTagRecords(for:  filters)
      
      expect(tags)
        .to(haveCount(3), description: "3 tags found or created")
        .to(containElementSatisfying({ $0.asFilter == filters[0] }))
        .to(containElementSatisfying({ $0.asFilter == filters[1] }))
        .to(containElementSatisfying({ $0.asFilter == filters[2] }))
    }
  }
  
    // MARK: - createTag
  
  @Suite(".createTag")
  struct CreateTag {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".createTag(forFilter:) - Creates a TagRecord for a FilteringTag")
    func test_create_tag_with_value() async throws {
      let tag: TagRecord = try service.createTag(forFilter: .tag("create-tag-test"))
      
      expect(tag)
        .to(map(\.value, equal("create-tag-test")))
        .to(map(\.asFilter, equal(.tag("create-tag-test"))))
    }
  }
  
  
    // MARK: - replaceTags
  @Suite(".replaceTags")
  struct ReplaceTags {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".replaceTags(forContent:withSet:) - Overwrites previous tag associations for content")
    func test_replace_tags_for_content() async throws {
      let newBakedGoods: [FilteringTag] = [.tag("danish"), .tag("tart"), .tag("muffin")]
      
      let newOfferings = try service.replaceTags(forContent: Eatery.bakery.id, withSet: newBakedGoods)
      
      expect(newOfferings)
        .to(haveCount(newBakedGoods.count))
      
      let tags = try service.getTags(forContent: Eatery.bakery.id)
      
      expect(tags).to(haveCount(newBakedGoods.count))
      
      expect(newBakedGoods)
        .to(allPass({ filter in
          tags.contains { $0.asFilter == filter }
        }))
    }
    
    @Test(".replaceTags(forContent:withSet:) - Overwrites previous tag associations for multiple contentIds")
    func test_replace_tags_for_many_content() async throws {
      let newBakedGoods: [FilteringTag] = [.tag("danish"), .tag("tart"), .tag("muffin")]
      
      let newTagIndxs = try service.replaceTags(
        forContent: [Eatery.bakery.id, Eatery.coffeeshop.id],
        withSet: newBakedGoods)
      
      expect(newTagIndxs).to(haveCount(newBakedGoods.count * 2))
      
      expect([Eatery.bakery.id, Eatery.coffeeshop.id]).to(allPass({ contentId in
        let tags = try service.getTags(forContent: contentId)
        
        expect(tags).to(haveCount(newBakedGoods.count))
        
        expect(newBakedGoods).to(allPass({ filter in
          tags.contains { $0.asFilter == filter }
        }))
        
        return true
      }))
    }
  }
  
    // MARK: - appendTags
  
  @Suite(".appendTags")
  struct AppendTags {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".appendTags(tags:toContent:) - Append tags")
    func test_append_tags_to_content() async throws {
      
      let newBakedGoods: [FilteringTag] = [.tag("toast"), .tag("bun")]
      let relevantEateries = [Eatery.bakery, Eatery.bbq]
      
      let newTagIndxs = try service.appendTags(newBakedGoods, toContent: relevantEateries.map(\.id))
      
      expect(newTagIndxs)
        .to(haveCount(newBakedGoods.count * 2))
      
      expect([Eatery.bakery, Eatery.bbq]).to(allPass({ eatery in
        
        let tags = try service.getTags(forContent: eatery.id)
        
        expect(tags.count).to(beGreaterThan(newBakedGoods.count))
        
        expect(newBakedGoods).to(allPass({ filter in
          tags.contains { $0.asFilter == filter }
        }))
        
        return true
      }))
    }
  }
  
  
  @Suite(".modifyTags")
  struct ModifyTags {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }

    @Test(".modifyTags(forContent:ensure:remove:) - Modify tags")
    func test_modify_tags_for_content() async throws {

      let newSupplies: [FilteringTag] = [.tag("napkins"), .tag("straws")]
      let recalledItems: [FilteringTag] = [Food.chicken, .porkchop].map(\.asFilter)
      
      let eateriesWithRecalledItems = Eatery.allCases.filter { $0.foods.contains(any: [.chicken, .porkchop]) }
      
      // let nonRecalledOfferings: [FilteringTag] = Eatery.allCases
      //   .flatMap(\.foods)
      //   .map(\.asFilter)
      //   .reject(where: { $0.oneOf(recalledItems) })

      let (_,removed) = try service.modifyTags(
        forContent: eateryIds,
        ensure: newSupplies,
        remove: recalledItems
      )
      
      expect(Eatery.allCases).to(allPass { eatery in
        let tags = try service.getTags(forContent: eatery.id)
        let expecting = eatery.foods.asFilters.reject(where: recalledItems.contains) + newSupplies
        
        expect(tags.map(\.asFilter))
          .to(haveCount(expecting.count), description: "tags for \(eatery.rawValue) to match expected count")
          .to(contain(expecting), description: "tags for \(eatery.rawValue) to match expected tags")
        
        return true
      })
      
      expect(removed)
        .to(haveCount(recalledItems.count * eateriesWithRecalledItems.count),
            description: "removed IndexTagRecords to equal number of eateries with recalled items")

      expect(try service.getTagRecord(for: Food.chicken.asFilter))
        .to(beNil(), description: "unsed tag \(Food.chicken.asFilter) to be removed")

      expect(try service.getTagRecord(for: Food.porkchop.asFilter))
        .to(beNil(), description: "unsed tag \(Food.porkchop.asFilter) to be removed")
    }
  }
  
  
    // MARK: - removeTag
  @Suite("removeTag")
  struct RemoveTag {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".removeTag(_ filter:) - Remove a tag entirely (no content associations)")
    func test_remove_tag_with_value() async throws {
      let removed = try service.removeTag(Food.chicken.asFilter, scope: .all)

      expect(removed).to(equal(2), description: "tag associations removed")
      
      let tags = try service.getTagRecord(for: Food.chicken.asFilter)

      expect(tags).to(beNil(), description: "TagRecord '\(Food.chicken)' not removed")
    }
    
    @Test(".removeTag(_:) - Throws error for non-existent tag")
    func test_remove_tag_with_value_throws() async throws {
      expect {
        try service.removeTag(.tag("Zebra"), scope: .all)
      }
      .to(throwError(), description: "Error thrown for non-existent tag")
    }
    
    @Test(".removeTag(_:matching:) - Remove tag from content matching query parameters")
    func test_remove_tag_with_value_matching() async throws {
      let hasDonuts = try service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonuts)
        .toNot(beNil())
        .to(contain([
          Eatery.bakery.id,
          Eatery.coffeeshop.id
        ]))
      
      let removed = try service.removeTag(Food.donuts.asFilter, matching: .init(
        rootDir: .temporaryDirectory, types: .all, visibility: .hidden
      ))
      
      expect(removed)
        .to(equal(1), description: "tag associations removed")
      
      let hasDonutsNow = try service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonutsNow)
        .toNot(beNil())
        .to(contain([
          Eatery.bakery.id
        ]))
    }
    
    @Test(".removeTag(_:fromContent:) - Remove tag from content with IDs")
    func test_remove_tag_from_content() async throws {
      let hasDonuts = try service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonuts)
        .toNot(beNil())
        .to(contain([
          Eatery.bakery.id,
          Eatery.coffeeshop.id
        ]))
      
      let removed = try service.removeTag(Food.donuts.asFilter, fromContent: [Eatery.bakery.id])

      expect(removed)
        .to(equal(1), description: "tag associations removed")
      
      let hasDonutsNow = try service.getContentIdAssociations(forTag: Food.donuts.id)

      expect(hasDonutsNow)
        .toNot(beNil())
        .to(contain([
          Eatery.coffeeshop.id
        ]))
    }
  }
  
    // MARK: - renameTag
  
  @Suite("renameTag")
  struct RenameTag {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    let applePie: FilteringTag = .tag("apple pie")
    
    @Test(".renameTag(_:to:) - Rename tag")
    func test_rename_tag_with_value_to() async throws {
      let hasDonuts = try service.getContentIdAssociations(forTag: Food.donuts.id)

      let (renamed, tagitems) = try service.renameTag(Food.donuts.asFilter, to: .tag("danish"))
      
      expect(renamed)
        .to(map(\.value, equal("danish")))
        .to(map(\.rawValue, equal(.tag)))
        .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")

      expect(tagitems)
        .to(haveCount(hasDonuts.count), description: "number of tag associations updated")
      
      let tagRecord = try service.getTagRecord(for: .tag("danish"))
      
      expect(tagRecord)
        .toNot(beNil(), description: "post-rename fetched tag")
        .to(equal(renamed), description: "matches tag returned from renameTag")
        .to(map(\.asFilter, equal(.tag("danish"))), description: "tag renamed to 'danish'")
        .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")
    }
    
    @Test(".renameTag(_:to:) - Apply new tag label")
    func test_rename_tag_change_tag_label() async throws {
      let hasDonuts = try service.getContentIdAssociations(forTag: Food.donuts.id)

      let (renamed, tagitems) = try service.renameTag(Food.donuts.asFilter, to: .artist("donuts"))
      
      expect(renamed)
        .to(map(\.value, equal("donuts")))
        .to(map(\.rawValue, equal(.artist)))
        .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")

      expect(tagitems)
        .to(haveCount(hasDonuts.count), description: "number of tag associations updated")
      
      let tagRecord = try service.getTagRecord(for: .artist("donuts"))
      
      expect(tagRecord)
        .toNot(beNil(), description: "post-rename fetched tag")
        .to(equal(renamed), description: "matches tag returned from renameTag")
        .to(map(\.asFilter, equal(.artist("donuts"))), description: "tag re-labeled tag to match artist|donuts'")
        .to(map(\.id, equal(Food.donuts.id)), description: "tag ID unchanged")
    }
    
    @Test(".renameTag(_:to:for:) - Rename tag for content IDs")
    func test_rename_tag_with_value_to_for() async throws {
      
      let (renamed, tagitems) = try service.renameTag(Food.pie.asFilter, to: applePie, for: [Eatery.diner.id])

      expect(renamed)
        .toNot(beNil())
        .to(beAKindOf(TagRecord.self))
        .to(map(\.asFilter, equal(applePie)))
      
      
      expect(tagitems).to(haveCount(1), description: "updated associations")
      
      expect(try service.getTagRecord(for: applePie))
        .notTo(beNil())
        .to(beAKindOf(TagRecord.self))
        .to(map(\.asFilter, equal(applePie)))
      
      expect(try service.getTagRecord(for: Food.pie.asFilter))
        .notTo(beNil())
        .to(beAKindOf(TagRecord.self))
        .to(map(\.asFilter, equal(Food.pie.asFilter)))
    }
    
    
      /// Rename tag "pie" to "Apple Pie" but only for items that also have "waffles"
      /// Pie is on 3 items: bakery, bbq, and diner, and only one of those has waffles: the classic diner
    @Test(".renameTag(_:to:matching:) - Rename tag for content matching query parameters")
    func test_rename_tag_with_value_to_matching() async throws {
      let params: IndxRequestParams = .init(
        rootDir: .temporaryDirectory,
        mode: .immediate(uncached: true),
        types: .all,
        tags: [Food.waffles.asFilter])

      let (renamed, tagitems) = try service.renameTag(Food.pie.asFilter, to: applePie, matching: params)
      
      expect(renamed)
        .toNot(beNil())
        .to(map(\.asFilter, equal(applePie)))
      
      expect(tagitems)
        .to(containElementSatisfying({ $0.contentId == Eatery.diner.id }))
        .to(haveCount(1), description: "only the diner has both waffles and pie")
      
      let itemsWithPlainPie = try service.getContentAssociations(tagId: Food.pie.id)

      expect(itemsWithPlainPie)
        .to(haveCount(2), description: "bakery and bbq dont serve waffles, should still have original pie")
        .to(containElementSatisfying({ $0.contentId == Eatery.bakery.id }))
        .to(containElementSatisfying({ $0.contentId == Eatery.bbq.id }))
    }
  }
  
  
    // MARK: - consolidateTag
  
  @Suite(".consolidateTag")
  struct ConsolidateTags {
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    let breakfast: FilteringTag = .tag("breakfast")
    let dinner: FilteringTag = .tag("dinner")
    let dessert: FilteringTag = .tag("dessert")
    
    @Test(".consolidateTag(_:into:) - Consolidate tag")
    func test_consolidate_tag_with_value_into() async throws {
      
      _ = try service.createTag(forFilter: breakfast)
      _ = try service.createTag(forFilter: dinner)
      _ = try service.createTag(forFilter: dessert)
      
      for item in [Food.donuts, .pancakes, .waffles] {
        _ = try service.consolidateTag(item.asFilter, into: breakfast)
      }

      for item in [Food.chicken, .porkchop, .soup] {
        _ = try service.consolidateTag(item.asFilter, into: dinner)
      }
      
      for item in [Food.cake, .cookies, .pie] {
        _ = try service.consolidateTag(item.asFilter, into: dessert)
      }
      
      
      await expect(try service.getTags(forContent: Eatery.bakery.id))
        .toEventually(haveCount(2), description: "bakery items")
        .toEventually(allPass { tagitem in
            [breakfast, dessert].contains(tagitem.asFilter)
        })
      
      await expect(try service.getTags(forContent: Eatery.bbq.id))
        .toEventually(haveCount(2), description: "bakery items")
        .toEventually(allPass { tagitem in
            [dinner, dessert].contains(tagitem.asFilter)
        })
      
      await expect(try service.getTags(forContent: Eatery.coffeeshop.id))
        .toEventually(haveCount(2), description: "bakery items")
        .toEventually(allPass { tagitem in
            [breakfast, dessert].contains(tagitem.asFilter)
        })
      
      await expect(try service.getTags(forContent: Eatery.diner.id))
        .toEventually(haveCount(3), description: "bakery items")
        .toEventually(allPass { tagitem in
            [breakfast, dinner, dessert].contains(tagitem.asFilter)
        })
      
      let _ = try await queue.read { db in
        try db.dumpRequest(IndexTagValueRecord.all().order(Column("contentId").desc), format: .debug())
      }
    }
    
    @Test(".consolidateTag(_:into:) - Consolidate tag into non-existent tag")
    func test_consolidate_tag_with_value_into_non_existent() async throws {
      let brunch: FilteringTag = .tag("brunch")
      
      expect {
        try service.consolidateTag(Food.chicken.asFilter, into: brunch)
      }
      .to(throwError { err in
        expect(err).to(matchError(IndexerServiceError.InvalidParameter(brunch.rawValue)))
      })
    }
    
    @Test(".consolidateTag(_:into:) - Consolidate tag into itself")
    func test_consolidate_tag_with_value_into_itself() async throws {
      let tagitems = try service.consolidateTag(Food.donuts.asFilter,
                                                into: Food.donuts.asFilter)
      
      expect(tagitems)
        .to(haveCount(2), description: "tag items affected by consolidated")

      await expect(try service.getTags(forContent: Eatery.bakery.id))
        .toEventually(haveCount(Eatery.bakery.foods.count), description: "bakery goods")
        .toEventually(allPass { tagitem in
          Eatery.bakery.foods.map(\.id).contains(tagitem.id)
        })

      await expect(try service.getTags(forContent: Eatery.coffeeshop.id))
        .toEventually(haveCount(Eatery.coffeeshop.foods.count), description: "coffeeshop items")
        .toEventually(allPass { tagitem in
          Eatery.coffeeshop.foods.map(\.id).contains(tagitem.id)
        })
    }
  }
  
    // MARK: - removeTagIfUnused
  
  @Suite("removeTag")
  struct RemoveTagIfUnused {
    
    var service: GRDBIndexService
    var queue: DatabaseQueue
    
    init() async throws {
      (service,queue) = try await TestSupportDB.setupDB()
    }
    
    @Test(".removeTag(_:scope:) - Removes associations and TagRecord when no associations remain")
    func test_remove_tag_if_unused() async throws {
      var tagCases = Foods.allFoods

      while !tagCases.isEmpty {
        guard let tag = tagCases.removeLastSafetly() else {
//          tagCases.removeAll()
          break
        }
        
        let deleteCount = try service.removeTag(tag.asFilter, scope: .all)
        
        expect(deleteCount).to(beGreaterThan(0))
      }
      
      let tagitems = try service.getContentAssociations(tagId: foodIds)
      
      expect(tagitems).to(beEmpty(), description: "remaining tag associations")
      
      expect(tagCases)
        .to(allPass({ tag in
          let tagRecord = try service.getTagRecord(for: tag.asFilter)
          return tagRecord == nil
        }))
    }
    
    @Test(".removeTag(_:fromContent:) - Does not remove tag with associations")
    func test_remove_tag_if_unused_with_value_not_removed() async throws {
      let deleteCount = try service.removeTag(Food.donuts.asFilter, fromContent: [Eatery.bakery.id])

      expect(deleteCount)
        .to(equal(1), description: "tag associations removed")
      
      let tagRecord = try service.getTagRecord(for: Food.donuts.asFilter)
      let remaining = try service.getContentAssociations(tagId: Food.donuts.id)

      expect(tagRecord)
        .toNot(beNil())
        .to(map(\.id, equal(Food.donuts.id)))

      expect(remaining)
        .to(haveCount(1), description: "tag associations remaining")
    }
  }
  
}
