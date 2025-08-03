// created on 5/13/25 by robinsr

import CustomDump
import GRDB


struct FilteringTagMultiParam: MultiValueQueryParam {
  
  typealias Filter = FilteringTag.Filter
  typealias Effect = FilteringTag.FilterEffect
  
  
  // Non-functional parameter only used to differentiate between requests
  var id: String = .randomIdentifier(24)
  
  private(set) var filters: [Filter]
  
  @available(*, deprecated, renamed: "filters", message: "Use `filters`; `values` is ambiguous")
  var values: [Value] { filters }
  
  var filterOpr: FilterOperator
  var enabled: Bool = true
  
  
  
  
  init(_ values: [Value],
       operator filterOpr: FilterOperator = .or,
       isEnabled enabled: Bool = true
  ) {
    self.filters = values
    self.filterOpr = filterOpr
    self.enabled = enabled
  }
  
  
  /// The filteringtag values to be used in the query.
  private var _values: [Value] {
    enabled ? filters : []
  }
  
  /// The number of FilteringTag members in the set. If the multi-param is disabled, this will be 0.
  var isEmpty: Bool {
    filters.isEmpty
  }
  
    /// The number of FilteringTag members in the set. If the multi-param is disabled, this will be 0.
  var count: Int {
    filters.count
  }
  
  func inclusiveValues(inDomains domains: FilteringTag.TagDomain...) -> [Value] {
    _values
      .filter { $0.tag.domain.oneOf(domains) }
      .inclusive
  }
  
  func exclusiveValues(inDomains domains: FilteringTag.TagDomain...) -> [Value] {
    _values
      .filter { $0.tag.domain.oneOf(domains) }
      .exclusive
  }
  
  func clone(withValues newValues: [Filter]) -> Self {
    .init(newValues, operator: filterOpr, isEnabled: enabled)
  }
  
  func clone(withOperator opr: FilterOperator) -> Self {
    .init(filters, operator: opr, isEnabled: enabled)
  }
  
  func clone(withEnabled enabled: Bool) -> Self {
    .init(filters, operator: filterOpr, isEnabled: enabled)
  }
  
  func setOperator(_ opr: FilterOperator) -> Self {
    clone(withOperator: opr)
  }
  
  func toggleOperator() -> Self {
    clone(withOperator: filterOpr.inverse)
  }
  
  func setEnabled(_ enabled: Bool) -> Self {
    clone(withEnabled: enabled)
  }
  
  func appending(_ filter: Value) -> Self {
    appending([filter])
  }
  
  func appending(_ newItems: [Value]) -> Self {
    clone(withValues: filters + newItems)
  }
  
  func appending(_ newTag: FilteringTag, as effect: Effect = .inclusive) -> Self {
    clone(withValues: filters.appending(Value(tag: newTag, effect: effect)))
  }
  
  func appending(_ newFilters: [FilteringTag], as effect: Effect = .inclusive) -> Self {
    clone(withValues: filters.appending(newFilters.map { Value(tag: $0, effect: effect) }))
  }
  
  func remove(_ tag: FilteringTag) -> Self {
    clone(withValues: filters.filter { $0.tag.rawValue != tag.rawValue })
  }
  
  func remove(_ value: Value) -> Self {
    clone(withValues: filters.filter { $0 != value })
  }
  
  func removeAll() -> Self {
    clone(withValues: [])
  }
  
  func invertFilter(_ tag: FilteringTag) -> Self {
    guard let filter = value(for: tag) else {
      return self // no-op if the filter is not present
    }
    
    return replace(filter, with: filter.inverted)
  }
  
  func replace(_ prev: FilteringTag.Filter, with next: FilteringTag.Filter) -> Self {
    clone(withValues: filters.replacing([prev], with: [next]))
  }
  
  func replace(_ oldTag: FilteringTag, with newTag: FilteringTag, as effect: Effect = .inclusive) -> Self {
    let newValue: Value = Value(tag: newTag, effect: effect)
    
    guard
      let oldValue = filters.first(where: { $0.tag.rawValue == oldTag.rawValue })
    else {
      return self
    }
    
    return clone(withValues: filters.replacing([oldValue], with: [newValue]))
  }
  
  func value(for tag: FilteringTag) -> Value? {
    filters.first { $0.tag.rawValue == tag.rawValue }
  }
}


extension FilteringTagMultiParam: CustomStringConvertible, CustomDumpStringConvertible {
  var description: String {
    """
    FilteringTagMultiParam(
      id: \(id),
      enabled: \(enabled),
      filters: \(filters),
      filterOpr: \(filterOpr)
    )
    """
  }
  
  var customDumpDescription: String {
    description
  }
}


extension FilteringTagMultiParam: Hashable, Equatable {
  static func == (lhs: FilteringTagMultiParam, rhs: FilteringTagMultiParam) -> Bool {
    // Note: We do not compare `id` as it is randomly generated and does not affect equality.
    lhs.enabled == rhs.enabled &&
    lhs.filters == rhs.filters &&
    lhs.filterOpr == rhs.filterOpr
  }
  
  func hash(into hasher: inout Hasher) {
    // Note: We do not hash the `id` as it is generated randomly and does not affect equality.
    hasher.combine(filters.map(\.description).sorted())
    hasher.combine(filterOpr)
    hasher.combine(enabled)
  }
}


extension FilteringTagMultiParam: Codable {
  enum CodingKeys: String, CodingKey {
    case filters, filterOpr, enabled
  }
}
