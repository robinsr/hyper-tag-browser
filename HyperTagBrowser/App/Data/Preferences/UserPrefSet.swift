// created on 1/25/25 by robinsr

import Defaults


/**
  A protocol for defining a user preference to allow for a consistent interface for user preferences.
 */
protocol UserPrefSet<T>: PreferenceTip, Identifiable {
  associatedtype T: Defaults.Serializable
  
  var id: String { get }
  var label: String { get }
  var defaultsKey: Defaults.Key<T> { get }
}
