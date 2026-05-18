// created on 12/14/24 by robinsr

import Foundation
import GRDB

@testable import TaggedFileBrowser


struct IndexTagRecordFixture: DatabaseTestFixtureType {
  typealias RecordType = IndexTagRecord
  
  typealias Cols = RecordType.Columns
  
  typealias Tags = TagRecordFixture
  typealias Indx = IndexRecordFixture.Cases

  static var data: [DatabaseFixtureRow] {
    associations.flatMap { association in
      
      let rowId = try! association.fixtureRow.string(for: "id")
      
      let tags = association.fixtureMap["TagRecord"] ?? []
      
      return tags.map { tag in
        let tagId = try! tag.string(for: "id")
        
        let tagItemRow: DatabaseFixtureRow = [
          Cols.id.name: String.randomIdentifier(5, prefix: "tagitem:").databaseValue,
          Cols.tagId.name: tagId.databaseValue,
          Cols.contentId.name: rowId.databaseValue,
        ]
        
        return tagItemRow
      }
    }
  }
  
  static let associations: [DatabaseFixtureRow.Association] = [
    .init(Indx.bakery.asRow, ["TagRecord": Tags.bakeryGoods.map{ $0.asRow }]),
    .init(Indx.bbq.asRow, ["TagRecord": Tags.bbqGoods.map{ $0.asRow }]),
    .init(Indx.diner.asRow, ["TagRecord": Tags.dinerGoods.map{ $0.asRow }]),
    .init(Indx.coffeeshop.asRow, ["TagRecord": Tags.coffeeShopGoods.map{ $0.asRow }]),
  ]
  
  nonisolated(unsafe) static let dbRows: [GRDB.Row] = data.map { Row($0) }
  
  static let ids: [String] = data.map { $0["id"]?.storage.value as! String }
  
  static let records: [IndexTagRecord] = dbRows.compactMap { try? IndexTagRecord(row: $0) }
  
  static func withId(_ id: String) -> DatabaseFixtureRow? {
    data.first { row in
      try! row.string(for: "id") == id
    }
  }
}
