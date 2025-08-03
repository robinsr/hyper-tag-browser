// created on 11/15/24 by robinsr

import GRDB


enum ContentItemVisibility: String, Codable, CaseIterable, CustomStringConvertible {
  /// User-defined visibility on indexed content
  case normal, hidden
  
  /// Visibility when the content's location no longer resolves
  case lost
  
  /// Value to represent any visibility
  case any
  
  var inverse: Self {
    switch self {
    case .normal: return .hidden
    case .hidden: return .normal
    default: return self
    }
  }
  
  var description: String {
    self.rawValue.capitalized
  }
  
  static var allCases: [ContentItemVisibility] {
    [.normal, .hidden, .any] // .lost omitted intentionally
  }
  
  var acceptableValues: [ContentItemVisibility] {
    switch self {
    case .normal, .hidden: return [self]
    case .any: return [.hidden, .normal]
    default: return [self]
    }
  }
}

extension ContentItemVisibility: SQLExpressible {
  var sqlExpression: SQLExpression {
    switch self {
    case .any: return "%".sqlExpression
    default: return self.rawValue.sqlExpression
    }
  }
}

extension ContentItemVisibility: SelectableOptions {
  static var asSelectables: [SelectOption<Self>] {
    allCases.map { SelectOption(value: $0, label: $0.description) }
  }
}

extension ContentItemVisibility: DatabaseValueConvertible {
  var databaseValue: DatabaseValue {
    DatabaseValue(value: self.rawValue)!.databaseValue
  }

  static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
    guard let stringValue = String.fromDatabaseValue(dbValue) else {
      return nil
    }
    return ContentItemVisibility(rawValue: stringValue)
  }
}
