// created on 11/24/25 by robinsr

extension AppViewModel {

    // MARK: - Browse Filter Actions Impl

  func doAddBrowseFilter(_ filter: FilteringTag.Filter) {
    query.tagsMatching = query.tagsMatching.appending(filter)
  }
  
  func doRemoveBrowseFilter(_ filter: FilteringTag) {
    query.tagsMatching = query.tagsMatching.remove(filter)
  }
  
  func doReplaceBrowseFilter(_ filter: FilteringTag, with newTag: FilteringTag) {
    query.tagsMatching = query.tagsMatching.replace(filter, with: newTag)
  }
  
  func doInvertBrowseFilter(_ filter: FilteringTag) {
    query.tagsMatching = query.tagsMatching.invertFilter(filter)
  }
  
  func doClearBrowseFilters() {
    query.tagsMatching = query.tagsMatching.removeAll()
  }
}
