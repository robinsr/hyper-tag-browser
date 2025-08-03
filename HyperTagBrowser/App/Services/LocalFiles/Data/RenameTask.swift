// created on 6/8/25 by robinsr

import Foundation
import System


struct RenameTask: Encodable, PlannedTask, Sendable, CustomStringConvertible {
  let taskType: PlannedTaskType = .renameFile
  var taskState: PlannedTaskState = .pending
  let contentId: ContentId
  let previous: FilePath
  let updated: FilePath
  
  init(taskState: PlannedTaskState = .pending, contentId: ContentId, previous: FilePath, updated: FilePath) {
    self.taskState = taskState
    self.contentId = contentId
    self.previous = previous
    self.updated = updated
    
    if previous == updated {
      // If the previous and updated paths are the same, mark as completed immediately
      self.taskState = .completed
      print("RenameTask initialized with no changed needed: \(previous.string)")
    }
  }
  
  func complete() -> Self {
    .init(taskState: .completed, contentId: contentId, previous: previous, updated: updated)
  }
  
  func fail(_ error: Error) -> Self {
    // TODO: Will this work to detect file already exists?
    if case LocalFileServiceError.targetFileAlreadyExists(let path) = error {
      print("RenameTask fail: target file already exists at \(path.string)")
      return RenameTask(
        taskState: .failed(error: "File already exists"),
        contentId: contentId,
        previous: previous,
        updated: updated)
    } else {
      return RenameTask(
        taskState: .failed(error: error.legibleLocalizedDescription),
        contentId: contentId,
        previous: previous,
        updated: updated)
    }
  }
  
  func fail(_ fsError: LocalFileServiceError) -> Self {
    return fail(fsError as Error)
  }
  
  var isNoop: Bool {
    previous == updated
  }
  
  var description: String {
    """
    RenameTask(
      taskState: \(taskState)
      contentId: \(contentId.value)
      previous: \(previous.string)
      updated: \(updated.string)
    )
    """
  }
  
  var isRename: Bool {
    previous.directory == updated.directory
  }
  
  var isRelocated: Bool {
    previous.directory != updated.directory
  }
  
  
  var successMessage: String {
    if isRename {
      return "Renamed \(previous.baseName) to \(updated.baseName)"
    }
    
    if isRelocated {
      return "Relocated \(updated.baseName) to \(updated.directory.baseName)"
    }
    
    return "Renamed '\(previous.string)' to '\(updated.string)'"
  }
  
  var failureMessage: String {
    if isRename {
      return "Failed renaming file to \(updated.baseName): \(taskState.error)"
    }
    
    if isRelocated {
      return "Failed Relocating \(updated.baseName) to \(updated.directory.baseName): \(taskState.error)"
    }
    
    return "Rename failed: \(taskState.error)"
  }
}
