// created on 5/3/25 by robinsr

enum DataRetentionOption: String, CaseIterable, Identifiable, CustomStringConvertible {
  case preserve
  case discard
  
  var id: String { rawValue }
  
  var description: String {
    rawValue.capitalized
  }
}
