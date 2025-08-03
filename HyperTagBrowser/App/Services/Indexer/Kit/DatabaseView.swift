// created on 1/15/25 by robinsr

import GRDB

protocol DatabaseView: TableRecord {
  static var cteExpression: String { get }
}
