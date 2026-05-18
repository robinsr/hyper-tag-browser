// created on 11/24/25 by robinsr

extension AppViewModel {
    
    // MARK: - Bookmarking Actions IMPL
  
  func doCreateBookmark(to content: ContentItem) {
    guard content.conforms(to: .folder) else {
      messages.send(reject: "Cannot create bookmark for non-folder item")
      return
    }
    
    Task {
      do {
        let bookmark = try await indexer.createBookmark(to: content.id)
        messages.send(ok: "Created new bookmark \(bookmark.name.quoted)")
      } catch {
        messages.send(ErrorMsg("Error creating bookmark for folder: \(content.name.quoted)", error))
      }
    }
  }
  
  func doDeleteBookmark(_ bookmark: BookmarkItem) {
    Task {
      do {
        if let deleted = try await indexer.deleteBookmark(withId: bookmark.id) {
          messages.send(ok: "Bookmark to '\(deleted.name)' deleted")
        } else {
          messages.send(err: "Bookmark not found")
        }
      } catch {
        messages.send(ErrorMsg("Error deleting bookmark", error))
      }
    }
  }
  
  func doDeleteBookmarks(to content: ContentItem) {
    Task {
      do {
        let deleted = try await indexer.deleteBookmarks(to: content.id)
        
        if deleted.count > 0 {
          messages.send(ok: "Bookmark to '\(content.filepath.baseName)' deleted")
        } else {
          messages.send(err: "Bookmark not found")
        }
      } catch {
        messages.send(ErrorMsg("Error deleting bookmark", error))
      }
    }
  }
  
  
  
  func toggleCurrentLocationBookmark() {
    Task {
      do {
        if let bookmark = try await indexer.findBookmark(withPath: currentPath) {
          return self.doDeleteBookmark(bookmark)
        }
      } catch {
        return messages.send(ErrorMsg("Could not bookmark for current location", error))
      }

      do {
        var contentItem = try await indexer.getContentItem(atPath: currentPath)
        
        if contentItem == nil {
          contentItem = try await indexer.createIndex(for: currentPath)
        }
        
        if let record = contentItem {
          self.doCreateBookmark(to: record)
        }
      } catch {
        messages.send(ErrorMsg("Error toggling bookmark for current location", error))
      }
    }
  }
}
