// created on 3/4/25 by robinsr

import Foundation


protocol MultiValueQueryParam: Codable, Equatable, Hashable {
  associatedtype Value
  
  var id: String { get }
  var values: [Value] { get }
  var filterOpr: FilterOperator { get }
  var isEmpty: Bool { get }
  var count: Int { get }
  func clone(withValues: [Value]) -> Self
  func setOperator(_ operator: FilterOperator) -> Self
}
