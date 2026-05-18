// created on 1/11/26 by robinsr


// TODO: Why does this exist?
struct UIActivationState: OptionSet, CustomStringConvertible {
  let rawValue: Int
  
  static let none = UIActivationState(rawValue: 1 << 0)
  static let active = UIActivationState(rawValue: 1 << 1)
  static let inactive = UIActivationState(rawValue: 1 << 2)
  static let all = UIActivationState(rawValue: 1 << 4)
  
  func contains(any values: UIActivationState...) -> Bool {
    values.filter {
      self.contains($0)
    }.isEmpty == false
  }
  
  var isEmpty: Bool {
    self.rawValue == 0
  }
  
  var never: Bool {
    contains(.none) || isEmpty
  }
  
  var active: Bool {
    contains(any: .active, .all) && !never
  }
  
  var inactive: Bool {
    contains(any: .inactive, .all) && !never
  }
  
  var description: String {
    var mems = [String]()
    
    if contains(.none) { mems.append("none") }
    if contains(.all) { mems.append("all") }
    if contains(.active) { mems.append("active") }
    if contains(.inactive) { mems.append("inactive") }
    
    return "UIActivationState(\(mems.joined(separator: ",")))"
  }
  
  static var allCases: [UIActivationState] {
    return [.none, .all, .active, .inactive]
  }
}
