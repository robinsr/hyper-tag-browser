// created on 2/2/25 by robinsr


/**
 Defines properties for objects that can be used as actions in a menu or context menu.
 */
protocol MenuActionable {
  var label: String { get }
  var icon: String? { get }
}
