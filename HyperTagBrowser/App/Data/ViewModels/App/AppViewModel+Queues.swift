// created on 11/24/25 by robinsr

import Defaults
import Factory
import Foundation


extension AppViewModel {
  
    // MARK: - Queue Actions IMPL
  
  func doCreateQueue(named name: String) {
    Task {
      do {
        let queue = try await indexer.createQueue(named: name)
        messages.send(ok: "Created new queue '\(name)' (\(queue.id))")
      } catch {
        messages.send(ErrorMsg("Error creating queue", error))
      }
    }
  }
  
  func doInsertContent(_ pointers: [ContentPointer], into tag: FilteringTag) {
    Task {
      do {
        let _ = try await indexer.tag(tag, on: pointers.map(\.contentId))
        
        messages.send(ok: "Added item to \(tag.displayString)")
      } catch {
        messages.send(ErrorMsg("Error adding content to tag", error))
      }
    }
  }
}
