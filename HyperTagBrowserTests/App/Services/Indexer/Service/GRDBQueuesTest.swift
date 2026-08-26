// created on 2026-08-26 by robinsr

import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser


@Suite("GRDBQueues", .serialized, .tags(.indexer))
struct GRDBQueuesTest {

  typealias Eatery = IndexRecordFixture.Cases

  var service: GRDBIndexService
  var queue: DatabaseQueue

  init() async throws {
    (service, queue) = try await TestSupportDB.setupDB()
  }

  // MARK: - createQueue

  @Test("createQueue returns a QueueRecord with a non-empty id")
  func test_create_queue_returns_record() async throws {
    let record = try await service.createQueue(named: "test-queue")
    expect(record.id).notTo(beEmpty())
    expect(record.name).to(equal("test-queue"))
  }

  @Test("createQueue persists the queue to the database")
  func test_create_queue_persists() async throws {
    let record = try await service.createQueue(named: "persisted-queue")
    let fetched = try await queue.read { db in
      try QueueRecord.fetchOne(db, key: record.id)
    }
    expect(fetched).notTo(beNil())
    expect(fetched?.name).to(equal("persisted-queue"))
  }

  @Test("no queues exist initially")
  func test_no_queues_initially() async throws {
    let all = try await queue.read { db in
      try QueueRecord.fetchAll(db)
    }
    expect(all).to(beEmpty())
  }

  // MARK: - insertIntoQueue

  @Test("insertIntoQueue(queueId:content:ContentId) adds a single item")
  func test_insert_single_content_into_queue() async throws {
    let queueRecord = try await service.createQueue(named: "single-item-queue")
    let contentId = Eatery.bakery.id

    try await service.insertIntoQueue(queueId: queueRecord.id, content: contentId)

    let items = try await queue.read { db in
      try QueueItemRecord.fetchAll(db)
    }
    expect(items).to(haveCount(1))
    expect(items.first?.queueId).to(equal(queueRecord.id))
    expect(items.first?.contentId).to(equal(contentId))
  }

  @Test("insertIntoQueue(queueId:content:[ContentId]) adds multiple items")
  func test_insert_multiple_content_into_queue() async throws {
    let queueRecord = try await service.createQueue(named: "multi-item-queue")
    let contentIds: [ContentId] = [Eatery.bakery.id, Eatery.bbq.id, Eatery.diner.id]

    try await service.insertIntoQueue(queueId: queueRecord.id, content: contentIds)

    let items = try await queue.read { db in
      try QueueItemRecord.fetchAll(db)
    }
    expect(items).to(haveCount(3))
    let insertedContentIds = items.map(\.contentId)
    expect(insertedContentIds).to(contain(Eatery.bakery.id))
    expect(insertedContentIds).to(contain(Eatery.bbq.id))
    expect(insertedContentIds).to(contain(Eatery.diner.id))
  }

  @Test("queue items are associated with the correct queue")
  func test_queue_items_associated_with_queue() async throws {
    let queueRecord = try await service.createQueue(named: "association-queue")
    let contentId = Eatery.coffeeshop.id

    try await service.insertIntoQueue(queueId: queueRecord.id, content: contentId)

    let items = try await queue.read { db in
      try QueueItemRecord
        .filter(QueueItemRecord.Columns.queueId == queueRecord.id)
        .fetchAll(db)
    }
    expect(items).to(haveCount(1))
    expect(items.first?.contentId).to(equal(contentId))
  }

  @Test("multiple queues can hold items independently")
  func test_multiple_queues_hold_items_independently() async throws {
    let queueA = try await service.createQueue(named: "queue-a")
    let queueB = try await service.createQueue(named: "queue-b")

    try await service.insertIntoQueue(queueId: queueA.id, content: Eatery.bakery.id)
    try await service.insertIntoQueue(queueId: queueB.id, content: [Eatery.bbq.id, Eatery.diner.id])

    let itemsA = try await queue.read { db in
      try QueueItemRecord
        .filter(QueueItemRecord.Columns.queueId == queueA.id)
        .fetchAll(db)
    }
    let itemsB = try await queue.read { db in
      try QueueItemRecord
        .filter(QueueItemRecord.Columns.queueId == queueB.id)
        .fetchAll(db)
    }

    expect(itemsA).to(haveCount(1))
    expect(itemsB).to(haveCount(2))
    expect(itemsA.first?.contentId).to(equal(Eatery.bakery.id))
    let contentIdsB = itemsB.map(\.contentId)
    expect(contentIdsB).to(contain(Eatery.bbq.id))
    expect(contentIdsB).to(contain(Eatery.diner.id))
  }
}
