// created on 3/31/25 by robinsr


/**
 * Represents the core type of a content item in the app.
 */
typealias ContentItem = IndexInfoRecord


extension ContentItem {

    /// The title of the content item.
    var title: String {
        return self.name
    }
}


extension Sequence where Element == ContentItem {
  
  var ids: [ContentId] {
    self.map(\.id)
  }
  
  var pointers: [ContentPointer] {
    self.map(\.pointer)
  }
  
  var records: [IndexRecord] {
    self.map(\.index)
  }
  
  var transferables: ContentPointers {
    ContentPointers(self.pointers)
  }
  
  func contains(_ id: ContentId) -> Bool {
    self.contains { $0.id == id }
  }
  
  func item(for id: ContentId) -> Element? {
    self.first { $0.id == id }
  }
  
  func visibility(eq value: ContentItemVisibility) -> [Element] {
    self.filter {
      $0.index.visibility == value
    }
  }
}
