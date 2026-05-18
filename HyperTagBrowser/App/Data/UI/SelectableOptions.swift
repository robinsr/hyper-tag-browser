// created on 5/31/25 by robinsr

import UniformTypeIdentifiers


/**
 * Conforming to `SelectableOptions` allows a type to provide a list of `SelectOption` items
 * that can be used in a selection context, such as a menu or a list of options.
 */
protocol SelectableOptions<Value> {
  associatedtype Value: Hashable
  
  static var asSelectables: [SelectOption<Value>] { get }
}


/**
 * A structure representing an option that can be selected in a menu or list.
 */
struct SelectOption<Value>: Identifiable, MenuActionable where Value: Hashable {
  let id = UUID()
  let value: Value
  let label: String
  var icon: String?
  var disabled: Bool = false
}
