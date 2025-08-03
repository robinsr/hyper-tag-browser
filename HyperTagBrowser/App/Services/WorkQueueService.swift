// created on 11/7/24 by robinsr

import Foundation
import LegibleError
import System



protocol PlannedTask: Sendable {
  var taskType: PlannedTaskType { get }
  var taskState: PlannedTaskState { get }
}

enum PlannedTaskType: String, Encodable {
  case renameFile
  case generateThumbnail
}

enum PlannedTaskResult: String, Equatable, Hashable {
  case success
  case failure
}

enum PlannedTaskState: Encodable, Equatable, Hashable {
  case pending
  case completed
  case failed(error: String)
  
  var result: PlannedTaskResult {
    switch self {
    case .completed: return .success
    default: return .failure
    }
  }
  
  var error: String {
    switch self {
      case .failed(let error): return error
      default: return ""
    }
  }
  
  var isFailed: Bool {
    switch self {
      case .failed(_): return true
      default: return false
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .pending: try container.encode("pending")
    case .completed: try container.encode("completed")
    case .failed(let error): try container.encode(error)
    }
  }
}



struct GenerateThumbnailTask: PlannedTask, Sendable {
  let taskType: PlannedTaskType = .generateThumbnail
  var taskState: PlannedTaskState = .pending
  let contentId: ContentId
  let filepath: FilePath
  
  func complete() -> Self {
    .init(taskState: .completed, contentId: contentId, filepath: filepath)
  }
  
  func fail(_ error: Error) -> Self {
    .init(taskState: .failed(error: error.legibleLocalizedDescription),
          contentId: contentId,
          filepath: filepath)
  }
}
