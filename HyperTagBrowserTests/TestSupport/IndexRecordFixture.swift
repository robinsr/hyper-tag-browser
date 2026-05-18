// created on 12/14/24 by robinsr

import CustomDump
import Foundation
import GRDB
import UniformTypeIdentifiers

@testable import HyperTagBrowser


struct IndexRecordFixture: DatabaseTestFixtureType {
  typealias RecordType = IndexRecord
  
  typealias Tags = TagRecordFixture
  typealias Visibility = ContentItemVisibility
  
  static let tmpDir = URL.temporaryDirectory.filepath
  
  enum Cases: String, CaseIterable, Sendable {
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
          "id": self.id.databaseValue,
          "timestamp": Date.now.databaseValue,
          "name": "[testing] A nice bakery.JPG".databaseValue,
          "location": tmpDir.appending("jpeg_files").databaseValue,
          "volume": VolumeInfo.defaultVolumeName.databaseValue,
          "type": UTType.jpeg.identifier.databaseValue,
          "size": 1024.databaseValue,
          "created": Date.now.databaseValue,
          "modified": Date.now.databaseValue,
          "comment": "What sort of foods are in a bakery?".databaseValue,
          "visibility": Visibility.normal.rawValue.databaseValue,
        ]
      case .bbq:
        return [
          "id": self.id.value.databaseValue,
          "timestamp": Date.now.databaseValue,
          "name": "[testing] A sunny bbq cookout.JPG".databaseValue,
          "location": tmpDir.appending("jpeg_files").databaseValue,
          "volume": VolumeInfo.defaultVolumeName.databaseValue,
          "type": UTType.jpeg.identifier.databaseValue,
          "size": 1024.databaseValue,
          "created": Date.now.databaseValue,
          "modified": Date.now.databaseValue,
          "comment": "is so tasty".databaseValue,
          "visibility": Visibility.normal.rawValue.databaseValue,
        ]
      case .diner:
        return [
          "id": self.id.value.databaseValue,
          "timestamp": Date.now.databaseValue,
          "name": "[testing] An american classic.mp4".databaseValue,
          "location": tmpDir.appending("video_files").databaseValue,
          "volume": VolumeInfo.defaultVolumeName.databaseValue,
          "type": UTType.mpeg4Movie.databaseValue,
          "size": 1024.databaseValue,
          "created": Date.now.offset(adding: -1000, of: .day).time.databaseValue,
          "modified": Date.now.offset(adding: -300, of: .day).time.databaseValue,
          "comment": "Diners have breakfast, lunch, dinner, and PIE!".databaseValue,
          "visibility": Visibility.normal.rawValue.databaseValue,
        ]
      case .coffeeshop:
        return [
          "id": self.id.value.databaseValue,
          "timestamp": Date.now.databaseValue,
          "name": "[testing] A secret coffee shop (its hidden).mp4".databaseValue,
          "location": tmpDir.appending("video_files").databaseValue,
          "volume": VolumeInfo.defaultVolumeName.databaseValue,
          "type": UTType.mpeg4Movie.databaseValue,
          "size": 1024.databaseValue,
          "created": Date.now.offset(adding: -1000, of: .day).time.databaseValue,
          "modified": Date.now.offset(adding: -300, of: .day).time.databaseValue,
          "comment": "Coffee shops usually have more than coffee".databaseValue,
          "visibility": Visibility.hidden.rawValue.databaseValue,
        ]
      }
    }
  }
  
  static var data: [DatabaseFixtureRow] {
    Cases.allCases.map { $0.asRow }
  }
  
  static let associations: [DatabaseFixtureRow.Association] = []
  
  nonisolated(unsafe) static let dbRows: [GRDB.Row] = data.map { Row($0) }
  
  static let ids: [String] = data.map { row in
    return try! row.string(for: "id")
  }
  
  static let records: [IndexRecord] = dbRows.compactMap { IndexRecord(row: $0) }
  
  static func withId(_ id: String) -> DatabaseFixtureRow? {
    data.first { row in
      try! row.string(for: "id") == id
    }
  }
}
