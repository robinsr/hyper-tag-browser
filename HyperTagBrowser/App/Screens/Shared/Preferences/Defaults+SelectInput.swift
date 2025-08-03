// created on 4/9/25 by robinsr

import Defaults
import SwiftUI


extension Defaults {
  
  /**
   * A type that captures requirements of Defaults (Defaults.Serializable)
   * and by SwiftUI ForEach (Hashable)
   */
  typealias SelectableSerializable = Defaults.Serializable & Hashable
  
  /// A view for a any type of enum-like Defaults value
  struct SelectInput<T: SelectableSerializable>: View {
    let key: Defaults.Key<T>
    let label: String
    let options: [SelectOption<T>]
    
    @State var value: T
    
    init(key: Defaults.Key<T>, label: String, options: [SelectOption<T>]) {
      self.key = key
      self.label = label
      self.options = options
      self.value = Defaults[key]
    }
    
    init(_ pref: UserSelectPrefs<T>) {
      self.init(
        key: pref.defaultsKey,
        label: pref.label,
        options: pref.options.map { .init(value: $0, label: "\($0)") }
      )
    }
    
    var body: some View {
      MenuSelect(
        selection: $value,
        options: options,
        unselected: label,
        presentation: .picker,
        itemLabel: { _ in Text(verbatim: label) })
        .onChange(of: value) {
          Defaults[key] = value
        }
    }
  }
}
