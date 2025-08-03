// created on 5/13/25 by robinsr

import GRDB


struct StringValueMultiParam: MultiValueQueryParam {
  typealias Value = String
  
  var id: String = .randomIdentifier(24)
  
  var values: [Value]
  var filterOpr: FilterOperator
  
  init(_ values: [Value], operator: FilterOperator = .or) {
    self.values = values
    self.filterOpr = `operator`
  }
  
  var isEmpty: Bool {
    values.isEmpty
  }
  
  var count: Int {
    values.count
  }
  
  func clone(withValues values: [Value]) -> Self {
    .init(values, operator: filterOpr)
  }
  
  func setOperator(_ operator: FilterOperator) -> Self {
    .init(values, operator: `operator`)
  }
}


extension StringValueMultiParam: Hashable {
  func hash(into hasher: inout Hasher) {
    // Note: We do not hash the `id` as it is generated randomly and does not affect equality.
    hasher.combine(values.sorted())
    hasher.combine(filterOpr)
  }
  
  static func == (lhs: StringValueMultiParam, rhs: StringValueMultiParam) -> Bool {
    // Note: We do not hash the `id` as it is generated randomly and does not affect equality.
    lhs.values == rhs.values &&
    lhs.filterOpr == rhs.filterOpr
  }
}


extension StringValueMultiParam: Codable {
  enum CodingKeys: String, CodingKey {
    case values, filterOpr
  }
}
