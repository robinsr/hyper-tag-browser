// created on 11/24/25 by robinsr

extension AppViewModel {
  
    // MARK: - TagStash Actions IMPL

  func doUpdateTagStash(id: TagStash.ID, appending tag: FilteringTag) {
    doUpdateTagStash(id: id, appending: [tag])
  }
  
  func doUpdateTagStash(id: TagStash.ID, appending tags: [FilteringTag]) {
    let items = (tagStashes[id]?.contents ?? []).union(tags)
    let newStash = TagStash(id: id, contents: items)

    tagStashes.updateValue(newStash, forKey: id)
  }
  
  func doUpdateTagStash(id: TagStash.ID, removing tags: [FilteringTag]) {
    if let stash = tagStashes[id] {
      let newStash = TagStash(id: id, contents: stash.contents.subtracting(tags))

      tagStashes.updateValue(newStash, forKey: id)
    }
  }
  
  func doClearTagStash(id: TagStash.ID) {
    tagStashes.updateValue(TagStash(id: id), forKey: id)
  }
  
  public func tagsStashed(in stashId: TagStash.ID) -> [FilteringTag] {
    tagStashes[stashId]?.contents.asArray ?? []
  }
}
