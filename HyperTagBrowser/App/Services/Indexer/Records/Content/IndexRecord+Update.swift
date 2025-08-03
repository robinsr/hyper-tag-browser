// created on 1/24/25 by robinsr

import Foundation
import GRDB
import System

extension IndexRecord {

  enum Update: RecordMutation, CustomStringConvertible {
    //case thumbnail(of: ContentScope, with: ImageDisplay)
    case name(of: ContentId, with: String)
    case location(of: [ContentId], with: FilePath)
    case visibility(of: [ContentId], with: ContentItemVisibility)

    var keys: [ContentId] {
      switch self {
//        case .thumbnail(let scope, _):
//          switch scope {
//            case .one(let pointer): return [pointer.contentId]
//            case .include(let pointers): return pointers.ids
//            default: return []
//          }

        case .name(let id, _):
          return [id]

        case .location(let ids, _),
          .visibility(let ids, _):
          return ids
      }
    }

    var recordCount: Int {
      keys.count
    }

    var location: FilePath? {
      if case .location(_, with: let path) = self { return path }
      return nil
    }

    var filename: String? {
      if case .name(_, with: let name) = self { return name }
      return nil
    }

//    var thumbnailConfig: ImageDisplay? {
//      if case .thumbnail(_, with: let config) = self { return config }
//      return nil
//    }

    var columnAssignment: IndexRecord.Columns {
      switch self {
        case .name(_, _):
          return Columns.name
        case .location(_, _):
          return Columns.location
        case .visibility(_, _):
          return Columns.visibility
      }
    }

    var assignment: ColumnAssignment {
      switch self {
        case .name(_, with: let name):
          return Columns.name.set(to: name)
        case .location(_, with: let path):
          return Columns.location.set(to: path)
        case .visibility(_, with: let vis):
          return Columns.visibility.set(to: vis.rawValue)
      }
    }

    var successMessage: String {
      switch self {
//        case .thumbnail(_, _):
//          return "Thumbnail updated"
        case .name(_, let name):
          return .init("Renamed file to `\(name)`")
        // return "Renamed file to '\(name)'"
        case .location(_, let path):
          return "Moved \("file", qty: recordCount) to '\(path.baseName)'"
        case .visibility(_, _):
          return "Visibility updated"
      }
    }

    var failedMessage: String {
      switch self {
//        case .thumbnail(_, _):
//          return "Failed to update thumbnail"
        case .name(_, _):
          return "Failed to update name"
        case .location(_, _):
          return "Failed to move files"
        case .visibility(_, _):
          return "Failed to update visibility"
      }
    }

    var description: String {
      switch self {
//        case .thumbnail(of: let id, with: let config):
//          return "Update thumbnail for \(id) with \(config)"
        case .name(of: let id, with: let name):
          return "Update name for \(id) to \(name)"
        case .location(of: let ids, with: let path):
          return "Move \("index", qty: ids.count) to '\(path.string)'"
        case .visibility(of: let ids, with: let vis):
          return "Update visibility for \("index", qty: ids.count) to \(vis)"
      }
    }
  }
}

protocol RecordMutation {
  var keys: [ContentId] { get }
  var recordCount: Int { get }
  var assignment: ColumnAssignment { get }
  var successMessage: String { get }
  var failedMessage: String { get }
}
