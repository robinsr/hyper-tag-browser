// created on 12/14/24 by robinsr

import Foundation
import UniformTypeIdentifiers
import GRDB
import CustomDump


struct IndexRecordFixture: DatabaseTestFixtureType {
  typealias RecordType = IndexRecord
  
  private typealias Tags = TagRecordFixture
  private typealias Vis = ContentItemVisibility
  
  static let tmpDir = URL.temporaryDirectory
  
  enum Cases: String, CaseIterable {
    case bakery
    case bbq
    case diner
    case coffeeshop
    
    var id: ContentId {
      .init(existing: "content:\(self.rawValue)")
    }
    
    func matches(_ record: IndexRecord) -> Bool {
      record.id == self.id
    }
    
    var foods: [TagRecordFixture.Cases] {
      switch self {
      case .bakery: return [.donuts, .cake, .cookies, .pie]
      case .bbq: return [.porkchop, .chicken, .pie]
      case .diner: return [.pancakes, .waffles, .soup, .chicken, .porkchop, .pie]
      case .coffeeshop: return [.donuts, .cookies, .cake]
      }
    }
    
    var cook: TagRecordFixture.Cases {
      switch self {
      case .bakery: return .baker
      case .bbq: return .grillmaster
      case .diner: return .chef
      case .coffeeshop: return .barista
      }
    }
    
    var asRow: DatabaseFixtureRow {
      switch self {
      case .bakery:
        return [
          "id": self.id.value,
          "name": "[testing] A nice bakery.JPG",
          "location": FixtureSupportFns.makeURL(tmpDir, "jpeg_files"),
          "volume": "Macintosh HD",
          "type": UTType.jpeg.identifier,
          "comment": "What sort of foods are in a bakery?",
          "visibility": Vis.normal.rawValue,
          "created": Date.now,
          "modified": Date.now,
          "lastOpened": Date.now,
        ]
      case .bbq:
        return [
          "id": self.id.value,
          "name": "[testing] A sunny bbq cookout.JPG",
          "location": FixtureSupportFns.makeURL(tmpDir, "jpeg_files"),
          "volume": "Macintosh HD",
          "type": UTType.jpeg.identifier,
          "comment": "is so tasty",
          "visibility": Vis.normal.rawValue,
          "created": Date.now,
          "modified": Date.now,
          "lastOpened": Date.now,
        ]
      case .diner:
        return [
          "id": self.id.value,
          "name": "[testing] An american classic.donut",
          "location": FixtureSupportFns.makeURL(tmpDir, "donut_files"),
          "volume": "Macintosh HD",
          "type": UTType.image.identifier,
          "comment": "Diners have breakfast, lunch, dinner, and PIE!",
          "visibility": Vis.normal.rawValue,
          "created": Date.now.offset(adding: -1000, of: .day).time,
          "modified": Date.now.offset(adding: -300, of: .day).time,
          "lastOpened": Date.now.offset(adding: -99, of: .day).time
        ]
      case .coffeeshop:
        return [
          "id": self.id.value,
          "name": "[testing] A secret coffee shop (its hidden).donut",
          "location": FixtureSupportFns.makeURL(tmpDir, "donut_files"),
          "volume": "Macintosh HD",
          "type": UTType.image.identifier,
          "comment": "Coffee shops usually have more than coffee",
          "visibility": Vis.hidden.rawValue,
          "created": Date.now.offset(adding: -1000, of: .day).time,
          "modified": Date.now.offset(adding: -300, of: .day).time,
          "lastOpened": Date.now.offset(adding: -99, of: .day).time
        ]
      }
    }
  }
  
  static var data: [DatabaseFixtureRow] {
    Cases.allCases.map { $0.asRow }
  }
  
  static let associations: [DatabaseFixtureRow.Association] = []
  
  static let dbRows: [GRDB.Row] = data.map { Row($0) }
  
  static let ids: [String] = data.map { $0.stringVal("id") }
  
  static let records: [IndexRecord] = dbRows.compactMap { IndexRecord(row: $0) }
  
  static func withId(_ id: String) -> DatabaseFixtureRow? {
    data.first { $0.stringVal("id") == id }
  }
}
