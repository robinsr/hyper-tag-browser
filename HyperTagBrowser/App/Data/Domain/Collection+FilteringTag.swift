// created on 5/13/25 by robinsr

extension Collection where Element == FilteringTag {
  var string: String {
    self.map { $0.value }.joined(separator: ", ")
  }
  
  func ofDomain(_ domain: FilteringTag.TagDomain) -> [Element] {
    self.filter { $0.domain == domain }
  }
}


extension Collection where Element == FilteringTag.Filter {
  var tags: [FilteringTag] {
    self.map { $0.tag }
  }
  
  var tagValues: [String] {
    self.map { $0.tag.value }
  }
  
  var summary: String {
    self.map { $0.tag.value }.joined(separator: ", ")
  }
  
  var inclusive: [Element] {
    self.filter { $0.effect == .inclusive }
  }
  
  var exclusive: [Element] {
    self.filter { $0.effect == .exclusive }
  }
  
  func ofDomain(_ domain: FilteringTag.TagDomain) -> [Element] {
    self.filter { $0.tag.domain == domain }
  }
}
