// created on 6/7/25 by robinsr


typealias AnyPreferenceTip = any PreferenceTip

protocol PreferenceTip: Identifiable {
  var id: String { get }
  var label: String { get }
  var helpText: String { get }
}
