// created on 6/3/25 by robinsr

/**
 * Defines the parameters for querying tags in the indexer.
 * */
struct TagQueryParameters: Codable, Identifiable, Copyable, Hashable {
  
  /// A unique identifier for the request, generated from the hash value of the parameters.
  var id: String {
    "\(self.hashValue)".hashId
  }
  
  /// Non-functional value only used to differentiate between requests
  let _nudge: Int
  
  /// The text string to match tag values agains
  let queryText: String
  
  /// Filter results to specific tag domains
  let tagDomains: [FilteringTag.TagDomain]
  
  /// Specific tags to exclude from the results
  let excludingTags: [FilteringTag]
  
  /// Specific tags to exclude from results (defined as tags on these content items)
  let excludingContent: [ContentId]
  
  /// Number of results to return
  let itemLimit: Int
  
  init(
    query: String,
    domains: [FilteringTag.TagDomain] = [.descriptive],
    excludingTags: [FilteringTag] = [],
    excludingContent: [ContentId] = [],
    itemLimit: Int = 10
  ) {
    self._nudge = Int.random(in: 0..<10000)
    self.queryText = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    self.tagDomains = domains
    self.excludingTags = excludingTags
    self.excludingContent = excludingContent
    self.itemLimit = itemLimit
  }
  
  var isEmpty: Bool {
    self.queryText.isEmpty
  }
}
