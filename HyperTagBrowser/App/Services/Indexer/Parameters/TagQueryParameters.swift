// created on 6/3/25 by robinsr

/**
 * Defines the parameters for querying tags in the indexer.
 * */
struct TagQueryParameters: Codable, Identifiable, Copyable, Hashable {
  
  /// A unique identifier for the request, generated from the hash value of the parameters.
  var id: String {
    get { "\(self.hashValue)".hashId }
    set { self._nudge += 1 } // This will change the hash value, effectively changing the id
  }
  
  /// Non-functional value only used to differentiate between requests
  var _nudge: Int = 0
  
  /// The text string to match tag values agains
  var queryText: String
  
  /// Filter results to specific tag domains
  var tagDomains: [FilteringTag.TagDomain] = [.descriptive]
  
  /// Specific tags to exclude from the results
  var excludingTags: [FilteringTag] = []
  
  /// Specific tags to exclude from results (defined as tags on these content items)
  var excludingContent: [ContentId] = []
  
  /// Number of results to return
  var itemLimit: Int = 10
  
}
