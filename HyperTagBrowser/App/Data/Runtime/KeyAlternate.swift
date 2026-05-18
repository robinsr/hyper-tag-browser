// created on 11/1/25 by robinsr

enum KeyAlternate {
  case primary
  case secondary
  case tertiary
  
  var isPrimary: Bool {
    self == .primary
  }
  
  var isSecondary: Bool {
    self == .secondary
  }
  
  var isTertiary: Bool {
    self == .tertiary
  }
}
