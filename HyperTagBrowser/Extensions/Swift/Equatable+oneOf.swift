// created on 12/5/24 by robinsr

extension Equatable {
  func oneOf(_ other: Self...) -> Bool {
    return other.contains(self)
  }
  
  func oneOf(_ others: [Self]) -> Bool {
    return others.contains(self)
  }
  
  func oneOf(_ others: Set<Self>) -> Bool where Self: Hashable {
    return others.contains(self)
  }
}
