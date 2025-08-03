// created on 12/14/24 by robinsr

import Foundation
import GRDB


struct IndexTagRecordFixture: DatabaseTestFixtureType {
  typealias RecordType = IndexTagRecord
  
  typealias Cols = RecordType.Columns
  
  typealias Tags = TagRecordFixture
  typealias Indx = IndexRecordFixture.Cases

  static var data: [DatabaseFixtureRow] {
    associations.flatMap { association in
      
      let rowId = association.fixtureRow.stringVal("id")
      
      let tags = association.fixtureMap["TagRecord"] ?? []
      
      return tags.map { tag in
        let tagId = tag.stringVal("id")
        
        let tagItemRow: DatabaseFixtureRow = [
          Cols.id.name: String.randomIdentifier(5, prefix: "tagitem:"),
          Cols.tagId.name: tagId,
          Cols.contentId.name: rowId,
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
  
  static let dbRows: [GRDB.Row] = data.map { Row($0) }
  
  static let ids: [String] = data.map { $0["id"] as! String }
  
  static let records: [IndexTagRecord] = dbRows.compactMap { try? IndexTagRecord(row: $0) }
  
  static func withId(_ id: String) -> DatabaseFixtureRow? {
    data.first { $0.stringVal("id") == id }
  }
}
