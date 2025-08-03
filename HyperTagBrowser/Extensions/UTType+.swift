// created on 3/12/25 by robinsr

import UniformTypeIdentifiers


extension UTType {
  func diverges(from type: UTType) -> Bool {
    self.conforms(to: type) == false
  }
}


extension Collection where Element == UTType {
  func diverges(from type: UTType) -> Bool {
    contains { $0.diverges(from: type) }
  }
  
  func conforms(to type: UTType) -> Bool {
    contains { $0.conforms(to: type) }
  }
  
  var typeIdentifiers: [String] {
    map { $0.identifier }.sorted()
  }
}
