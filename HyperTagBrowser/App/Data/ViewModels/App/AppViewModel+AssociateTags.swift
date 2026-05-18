// created on 11/24/25 by robinsr

import Factory


extension AppViewModel {
  
    // MARK: - Associating Tag Actions IMPL

  func doAssociateTags(_ tags: Tags, to scope: ContentScope) {
    if let disallowedErr = disallowScopeTypes([.global, .exclude, .atURL], scope: scope) {
      messages.send(reject: disallowedErr)
      return
    }
    
    Task {
      do {
        var results: [IndexTagRecord] = []
        
        if case .matching(let params) = scope {
          results = try await indexer.tag(tags, matching: params)
        }
        
        if scope.ids.notEmpty {
          results = try await indexer.tag(tags, on: scope.ids)
        }
        
        let contentIds = results.map(\.contentId).uniqued()
        
        if tags.count == 1, let tag = tags.first {
          messages.send(ok: "Tagged \("item", qty: contentIds.count) with \(tag.value.quoted)")
        } else {
          messages.send(ok: "Tagged \("item", qty: contentIds.count) with \("tag", qty: tags.count)")
        }
      } catch {
        messages.send(reject: .AssociationError(error))
      }
    }
  }
  
  
  func doDissociateTag(_ tag: FilteringTag, _ scope: ContentScope) {
    if let disallowedErr = disallowScopeTypes([.global, .exclude, .atURL], scope: scope) {
      messages.send(reject: disallowedErr)
      return
    }
    
    Task {
      do {
        var contentIds = scope.ids
        
        if case .matching(let params) = scope {
          contentIds = try await indexer.getIndexIds(matching: params)
        }
        
        let count = try await indexer.untag(tag, from: contentIds)
        
        messages.send(ok: "Removed \("tag associations", qty: count)")
      } catch {
        messages.send(reject: .AssociationError(error))
      }
    }
  }
  
  
  func doReplaceTags(_ tags: [FilteringTag], of scope: ContentScope) {
    if let disallowedErr = disallowScopeTypes([.global, .exclude, .atURL, .matching], scope: scope) {
      messages.send(reject: disallowedErr)
      return
    }
    
    guard scope.ids.notEmpty else {
      messages.send(reject: "No content selected to update tags")
      return
    }
    
    Task {
      do {
        let result = try await indexer.setTags(tags, on: scope.ids)
        
        messages.send(ok: "Updated \("item", qty: scope.ids.count) with \("tag", qty: result.count)")
      } catch {
        messages.send(ErrorMsg("Error updating tags", error))
      }
    }
  }
  
  func doRemoveTag(_ tag: FilteringTag, _ scope: BatchScope) {
    Task {
      do {
        let count = try await indexer.untag(tag, scope: scope)
        
        messages.send(ok: "\("associations", qty: count) of tag '\(tag.value, max: 20)' removed")
      } catch {
        messages.send(ErrorMsg("Error deleting tags", error))
      }
    }
  }
  
  func doRenameTag(_ tag: FilteringTag, _ value: String, _ scope: BatchScope) {
    guard let newTag = tag.type.makeTag(value) else {
      messages.send(err: "Invalid tag value")
      return
    }

    Task {
      do {
        switch scope {
        case .all:
          let (_, dbTagItems) = try await indexer.renameTag(tag, to: newTag)
          
          messages.send(ok: "Renamed tag on \("records", qty: dbTagItems.count) (all records)")
        case .visible:
          let updated = try await indexer.renameTag(tag, to: newTag, matching: query)
          
          messages.send(ok: "Renamed tag on \(updated) records")
        case .hidden:
          logger.emit(.warning, "removeFilteringTag(.hidden)")
        case .selected:
          logger.emit(.warning, "removeFilteringTag(.selected)")
        case .unselected:
          logger.emit(.warning, "removeFilteringTag(.unselected)")
        }
      } catch {
        messages.send(ErrorMsg("Error deleting tags", error))
      }
    }
  }
  
  func doRelabelTag(_ tag: FilteringTag, _ tagType: FilteringTag.TagType, _ scope: BatchScope) {
    guard let newTag = tagType.makeTag(tag.value) else {
      messages.send(err: "Invalid tag value '\(tag.value)' for tag type \(tagType)")
      return
    }

    Task {
      do {
        switch scope {
        case .all:
          let (_, dbTagItems) = try await indexer.renameTag(tag, to: newTag)
          
          messages.send(ok: "Renamed tag on \("records", qty: dbTagItems.count) (all records)")
        default:
          logger.emit(.warning, "removeFilteringTag")
          messages.send(err: "Scope \(scope) not supported")
        }
      } catch {
        messages.send(ErrorMsg("Error deleting tags", error))
      }
    }
  }
  
  
  func doNormalizeTags(from initial: Tags, keeping: Tags, pointers: Pointers) {
    let fromSet = Set(initial)
    let toSet = Set(keeping)
    let dropSet = fromSet.subtracting(toSet)

    Task {
      do {
        let (added, removed) = try await indexer.setTags(
          adding: toSet.asArray,
          removing: dropSet.asArray,
          on: pointers.map(\.contentId)
        )
        
        messages.send(ok: [
          "Updated \("item", qty: pointers.count):",
          "\("tags", qty: added.count) added,",
          "\("tags", qty: removed.count) removed",
        ])
      } catch {
        messages.send(ErrorMsg("Error modifying tags", error))
      }
    }
  }
  
  private func disallowScopeTypes(_ scopes: [ContentScope.Cases], scope: ContentScope) -> AppViewModelError? {
    guard scopes.contains(scope.caseType) else {
      return nil
    }
    
    switch scope.caseType {
      case .global:
        return .globalTag
      case .exclude:
        return .exBasedTagging
      case .matching:
        return .paramBasedTagging
      case .atURL:
        return .urlBasedTagging
      default:
      return .NotImplemented("Scope type \(scope.caseType.rawValue) not implemented for this action")
    }
  }
}
