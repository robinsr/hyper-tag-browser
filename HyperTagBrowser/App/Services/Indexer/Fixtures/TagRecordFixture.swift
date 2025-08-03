// created on 12/14/24 by robinsr

import Foundation
import GRDB


struct TagRecordFixture: DatabaseTestFixtureType {
  typealias RecordType = TagRecord
  
  static let fruitTags: [FilteringTag] = [
    .tag("Apples"),
    .tag("Mighty Banana"),
    .tag("Spicy Pepper"),
    .tag("Hearty Durian"),
    .tag("Voltfruit"),
    .tag("Wildberry"),
    .tag("Hydromelon"),
    .tag("Palm Fruit"),
    .tag("Splashfruit"),
    .tag("Dazzlefruit"),
  ]
  
  static let vegetableTags: [FilteringTag] = [
    .tag("Swift Carrot"),
    .tag("Endura Carrot"),
    .tag("Stamella Shroom"),
    .tag("Rushroom"),
    .tag("Razorshroom"),
    .tag("Ironshroom"),
    .tag("Silent Princess"),
    .tag("Courser Bee Honey"),
    .tag("Fleet-Lotus Seeds"),
  ]
  
  
  /// donuts, cake, cookies, pie
  static let bakeryGoods: [Cases] = [.donuts, .cake, .cookies, .pie]
  
  /// porkchop, chicken
  static let bbqGoods: [Cases] = [.porkchop, .chicken, .pie]
  
  /// pancakes, waffles, soup
  static let coffeeShopGoods: [Cases] = [.donuts, .cookies, .cake]
  
  /// pancakes, waffles, soup, porkchop
  static let dinerGoods: [Cases] = [.pancakes, .waffles, .soup, .chicken, .porkchop, .pie]
  
  static let allFoods: [Cases] = [
    .donuts, .chicken, .porkchop, .soup, .cookies, .cake, .pie, .pancakes, .waffles
  ]
  
  enum Cases: String, CaseIterable, Filterable {
    case donuts
    case chicken
    case porkchop
    case soup
    case cookies
    case cake
    case pie
    case pancakes
    case waffles
    
    case chef = "creator|chef"
    case baker = "creator|baker"
    case grillmaster = "creator|grillmaster"
    case barista = "creator|barista"

    
    
    var asRow: DatabaseFixtureRow {
      let filter = self.asFilter
      
      return [
        "id": self.id,
        "value": filter.value,
        "label": filter.type.rawValue,
        "type": TagRecord.EntryType.normal.rawValue,
      ]
    }
    
    var id: String {
      let alphas = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(separator: "").map { String($0) }
      
      let coded = String(asFilter.value)
        .split(separator: "")
        .map { String($0).uppercased() }
        .map { letter in
          alphas.firstIndex(where: { $0.uppercased() == letter }) ?? 0
        }
        .reduce("") { "\($0)\(alphas[$1])\($1)" }[0...6]
      
      return "tag:\(coded)"
    }
    
    var asFilter: FilteringTag {
      FilteringTag(self.rawValue)
    }
    
    func matches(_ record: TagRecord) -> Bool {
      record.id == self.id && record.asFilter == self.asFilter
    }
  }
  
  static var data: [DatabaseFixtureRow] {
    Cases.allCases.map { $0.asRow }
  }
  
  static var associations: [DatabaseFixtureRow.Association] = []
  
  static let dbRows: [GRDB.Row] = data.map { Row($0) }
  
  static let ids: [String] = data.map { $0.stringVal("id") }
  
  static let records: [TagRecord] = dbRows.map { row in
    do {
      return try TagRecord(row: row)
    } catch {
      fatalError("Error creating TagRecord: \(error)")
    }
  }
  
  static func withId(_ id: String) -> DatabaseFixtureRow? {
    data.first { $0.stringVal("id") == id }
  }
}


extension Array where Element == TagRecordFixture.Cases {
  var asFilters: [FilteringTag] {
    self.map { $0.asFilter }
  }
}
