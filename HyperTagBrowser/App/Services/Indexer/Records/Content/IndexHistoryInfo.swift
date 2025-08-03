// created on 3/19/25 by robinsr

import GRDB
import Foundation
import UniformTypeIdentifiers


struct IndexHistoryInfo: FetchableRecord, Decodable {
  var index: IndexRecord
  var transaction: IndexHistory
}


extension IndexHistory {
  
  typealias Query = QueryInterfaceRequest
  
  static func trackingRegion(
    status: Status,
    conformingTo uttype: UTType
  ) -> Query<IndexHistory> {
    IndexHistory
      .filter(Selections.status(status))
      .filter(Selections.contentType(conformsTo: uttype))
  }

  static func queryItems(
    status: Status,
    conformingTo uttype: UTType,
    secondsAgo seconds: TimeInterval = 3
  ) -> Query<IndexHistoryInfo> {
    let indexesOfType = index.forKey("index").all().withContentType(uttype)
    
    return IndexHistory.all()
      .order(Columns.timestamp.desc)
      .filter(Selections.status(status))
      .filter(Selections.withinLast(.seconds(seconds)))
      .including(required: indexesOfType)
      .asRequest(of: IndexHistoryInfo.self)
  }
  
  static func pendingItems() -> Query<IndexHistoryInfo> {
    queryItems(status: .pending, conformingTo: .content)
  }
  
  static func failedItems() -> Query<IndexHistoryInfo> {
    queryItems(status: .failed, conformingTo: .content)
  }
  
  static func pendingFolders() -> Query<IndexHistoryInfo> {
    queryItems(status: .pending, conformingTo: .folder)
  }
}
