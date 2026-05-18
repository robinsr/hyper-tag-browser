// created on 11/24/25 by robinsr

import Factory

extension AppViewModel {
    
    // MARK: - Saved Query Actions IMPL
  
  func doApplySavedQuery(id: BrowseFilters.ID) {
    logger.emit(.info, "Applying saved query with ID: \(id)")

    Task {
      do {
        guard let savedQueryRecord = try await indexer.getSavedQuery(withId: id) else {
          messages.send(reject: "Saved query with ID \(id) not found")
          return
        }
        
        messages.send(ok: "Applied filters from \(savedQueryRecord.name.quoted)")
      } catch {
        messages.send(ErrorMsg("Error applying saved query", error))
      }
    }
  }
  
  func doCreateSavedQuery(named name: String, with filters: BrowseFilters) {
    logger.emit(.info, "Creating new saved query with filters: \(json: filters)")

    Task {
      do {
        let saved = try await indexer.createSavedQuery(named: name, using: filters)
        
        messages.send(ok: "Saved query '\(name)' created with ID \(saved.id)")
      } catch {
        messages.send(ErrorMsg("Error creating saved query", error))
      }
    }
  }
  
  func doDeleteSavedQuery(id: BrowseFilters.ID) {
    logger.emit(.info, "Deleting saved query with ID: \(id)")

    Task {
      do {
        let deleted = try await indexer.deleteSavedQuery(withId: id)
        
        if deleted {
          messages.send(ok: "Saved query with ID \(id) deleted")
        } else {
          messages.send(reject: "Saved query with ID \(id) not found")
        }
      } catch {
        messages.send(ErrorMsg("Error creating saved query", error))
      }
    }
  }
  
  func doRenameSavedQuery(id: BrowseFilters.ID, to name: String) {
    logger.emit(.info, "Renaming saved query with ID: \(id) to name: \(name)")

    Task {
      do {
        let _ = try await indexer.renameSavedQuery(withId: id, to: name)
        
        messages.send(ok: "Saved query renamed to '\(name)'")
      } catch {
        messages.send(ErrorMsg("Error creating saved query", error))
      }
    }
  }
  
  func doUpdateSavedQuery(id: BrowseFilters.ID, with filters: BrowseFilters) {
    logger.emit(.info, "Updating saved query with ID: \(id) with filters: \(json: filters)")

    Task {
      do {
        let _ = try await indexer.updateSavedQuery(withId: id, using: filters)
        
        messages.send(ok: "Saved query with ID \(id) updated")
      } catch {
        messages.send(ErrorMsg("Error creating saved query", error))
      }
    }
  }
  
  func doLoadSavedQuery(withId id: BrowseFilters.ID) {
    logger.emit(.info, "Loading saved query with ID: \(id)")

    Task {
      let dispatch = Container.shared.dispatcher()
      
      do {
        if let saved = try await indexer.getSavedQuery(withId: id) {
          dispatch(.showSheet(.updateSavedQuerySheet(record: saved)))
        } else {
          messages.send(reject: "Saved query with ID \(id) not found")
        }
      } catch {
        messages.send(ErrorMsg("Error loading saved query", error))
      }
    }
  }
}
