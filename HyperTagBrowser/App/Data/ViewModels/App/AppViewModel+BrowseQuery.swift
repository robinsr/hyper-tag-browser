// created on 11/24/25 by robinsr

import System

extension AppViewModel {
    
    // MARK: - Browse Parameter Actions Impl
  
  func _setQueryLocation(to path: FilePath) {
    query.root = path
  }
  
  func doReloadQuery() {
    query.id = .randomIdentifier(32)
  }
  
  func doCycleSortMode() {
    query.sortBy = query.sortBy.nextCase
    messages.send(ok: "Sorting by \(query.sortBy.description)")
  }
  
  func setQueryListMode(_ mode: ListMode) {
    query.mode = mode
  }
  
  func toggleQueryListMode() {
    query.mode = query.mode.toggle(.cached)

    messages.send(ok: "\(query.mode.type.description) \(query.root.baseName.quoted)")
  }
  
  func setQuerySortMode(_ mode: SortType = .createdAtDesc) {
    query.sortBy = mode
  }
  
  func toggleQueryFilterOperator() {
    query.tagsMatching = query.tagsMatching.toggleOperator()
  }
  
  func setQueryFilterOperator(_ opr: FilterOperator) {
    query.tagsMatching = query.tagsMatching.setOperator(opr)
  }
  
  func setQueryVisibilityFilter(_ visibility: ContentItemVisibility) {
    query.visibility = visibility
  }
  
  func setQueryItemLimit(to limit: Int) {
    query.limit = limit
  }
  
  func setQueryTagFiltering(isEnabled: Bool) {
    query.tagsMatching = query.tagsMatching.setEnabled(isEnabled)
  }
}
