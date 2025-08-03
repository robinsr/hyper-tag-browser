// created on 5/13/25 by robinsr

import GRDB


extension SortType {
  var sqlOrdering: SQLOrdering {
    switch self {
    case .nameAsc:
      return IndexRecord.Columns.name.asc
    case .nameDesc:
      return IndexRecord.Columns.name.desc
    case .createdAtAsc:
      return IndexRecord.Columns.created.asc
    case .createdAtDesc:
      return IndexRecord.Columns.created.desc
    case .sizeAsc:
      return IndexRecord.Columns.size.detached.asc
    case .sizeDesc:
      return IndexRecord.Columns.size.detached.desc
    case .tagCountAsc:
      return IndexRecord.TableAliases.tagstring[IndexInfoRecord.Columns.tagCount.asc]
    case .tagCountDesc:
      return IndexRecord.TableAliases.tagstring[IndexInfoRecord.Columns.tagCount.desc]
    }
  }
}
