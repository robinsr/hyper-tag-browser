// created on 11/24/25 by robinsr

import Defaults
import Factory
import Foundation


extension AppViewModel {
    
    // MARK: - Modifying Content Actions IMPL

  func doEditName(of pointer: ContentPointer) {
    Task {
      let dispatch = Container.shared.dispatcher()
      
      do {
        if let result = try await indexer.getContentItem(withId: pointer.contentId) {
          dispatch(.showSheet(.renameContentSheet(item: result)))
        } else {
          messages.send(err: "No index found for item \(pointer.contentId)")
        }
      } catch {
        messages.send("Error fetching index", error)
      }
    }
  }
  
  func doEditTags(of pointers: [ContentPointer]) {
    Task {
      let dispatch = Container.shared.dispatcher()
      
      do {
        let records = try await indexer.getContentItems(withId: pointers.map(\.contentId))
        
        if records.count == 1 {
          dispatch(.showSheet(.editItemTagsSheet(item: records.first!, tags: records.first!.tags)))
          return
        }
        
        let allTags = records.map(\.tags)
        var commonTags = Set(allTags.first ?? [])
        
        for tags in allTags.dropFirst() {
          commonTags.formIntersection(tags)
        }
        
        dispatch(.showSheet(.editItemsTagsSheet(items: records, tags: commonTags.asArray)))
      } catch {
        messages.send(ErrorMsg("Error fetching tags for items", error))
      }
    }
  }
  
  func doUpdateIndex(with update: IndexRecord.Update) {
    Task {
      do {
        let _ = try await indexer.updateIndexes(with: update)
        messages.send(ok: update.successMessage)
      } catch {
        messages.send(ErrorMsg(update.failedMessage, error))
      }
    }
  }
  
  func doUpdateThumbnails(of records: [IndexRecord]) {
    Task.detached(priority: .background) { [self] in
      do {
        for index in records {
          try await thumbnailStore.clearThumbnail(forContent: index.id)
        }
        await messages.send(ok: "Updated thumbnails for \("items", qty: records.count)")
      } catch {
        await messages.send(ErrorMsg("Error updating thumbnails", error))
      }
    }
  }
}
