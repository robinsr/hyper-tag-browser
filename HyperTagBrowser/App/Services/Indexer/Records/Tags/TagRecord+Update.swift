// created on 2/22/25 by robinsr

import GRDB


extension TagRecord {
  enum Update {
    case fromFilter(FilteringTag)
    case tagValue(String)
    case tagType(FilteringTag.TagType)
    
    var assignment: [ColumnAssignment] {
      switch self {
      case .fromFilter(let filter):
        return [
          Columns.tagValue.set(to: filter.value),
          Columns.tagType.set(to: filter.type)
        ]
      case .tagValue(let newValue):
        return [
          Columns.tagValue.set(to: newValue)
        ]
      case .tagType(let newType):
        return [
          Columns.tagType.set(to: newType.rawValue)
        ]
      }
    }
    
    var successMessage: String {
      switch self {
      case .fromFilter(let filter):
        return "Updated tag value to '\(filter.value)' of type '\(filter.type.rawValue)'"
      case .tagValue(let value):
        return "Updated tag value to '\(value)'"
      case .tagType(let type):
        return "Updated tag type to '\(type)'"
      }
    }
    
    var failedMessage: String {
      switch self {
      case .fromFilter(let filter):
        return "Failed to update tag to match '\(filter.rawValue)'"
      case .tagValue(_):
        return "Failed to update tag value"
      case .tagType(_):
        return "Failed to update tag type"
      }
    }
  }
}
