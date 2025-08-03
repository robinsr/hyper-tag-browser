// created on 3/19/25 by robinsr

import GRDB


extension IndexHistory {
  
  var failed: IndexHistory.Update {
    .fsStatus(id: id, toStatus: .failed)
  }
  
  var pending: IndexHistory.Update {
    .fsStatus(id: id, toStatus: .pending)
  }
  
  var synced: IndexHistory.Update {
    .fsStatus(id: id, toStatus: .synced)
  }
  
  enum Update: CustomStringConvertible {
    case fsStatus(id: IndexHistory.ID, toStatus: Status)
    
    var key: IndexHistory.ID {
      switch self {
      case .fsStatus(id: let id, _): return id
      }
    }
    
    var status: Status? {
      switch self {
      case .fsStatus(_, toStatus: let status): return status
      }
    }
    
    var assignment: ColumnAssignment {
      switch self {
      case .fsStatus(_, toStatus: let status):
        return Columns.fsStatus.set(to: status.rawValue)
      }
    }
    
    var description: String {
      switch self {
      case .fsStatus(id: let id, toStatus: let status):
        "\(id?.formatted() ?? "unknown ID"): \(status)"
      }
    }
  }
}
