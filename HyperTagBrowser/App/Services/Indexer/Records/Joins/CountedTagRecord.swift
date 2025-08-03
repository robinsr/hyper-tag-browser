// created on 3/23/25 by robinsr

import GRDB


struct CountedTagRecord: FetchableRecord, Codable, Hashable, Filterable {
  var tag: TagRecord
  var count: Int
  
  var id: String { tag.id }
  var asFilter: FilteringTag { tag.asFilter }
  
  enum CodingKeys: String, CodingKey {
    case tag, count
  }
  
  enum Columns: String, ColumnExpression {
    case tag, count
  }
  
  static func query(matching params: TagQueryParameters) -> QueryInterfaceRequest<CountedTagRecord> {
    
    
    // Takes the `tagItems` association for each `TagRecord` (`tagItems` are the IndexTagRecord join table rows,
    // joining TagRecord to IndexRecords), and counts the number of items associated with each tag.
    let countingAggregate = TagRecord.tagItems.count.forKey(Columns.count.name)
    
    var request = TagRecord
      .all()
      .tagValueLike(params.queryText)
      .inTagDomains(params.tagDomains)
      .excluding(filters: params.excludingTags)
      .annotated(with: countingAggregate)
      .order(Columns.count.detached.desc)
      .limit(params.itemLimit)
      .asRequest(of: CountedTagRecord.self)
    
    if params.excludingContent.notEmpty {
      
      // A cta (not a subquery) producing a list of TagRecord IDs to filter from query results
      let subquery = IndexTagValueRecord.tagTable(for: params.excludingContent)
      
      request = request
        .with(subquery)
        .filter(!subquery.contains(TagRecord.Columns.id))
    }
    
    return request
  }
}
