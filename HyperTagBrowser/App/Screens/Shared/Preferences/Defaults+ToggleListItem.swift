// created on 6/7/25 by robinsr

import Foundation
import Defaults
import SwiftUI


extension Defaults {
  
  //typealias SelectableSerializable = Defaults.Serializable & Hashable
  
  /// A view for toggling items in a set of flags that are serializable and selectable.
  struct ToggleListItem<T: SelectableSerializable, Content: View>: View {
    
    var key: Defaults.Key<Set<T>>
    var value: T
    var label: (T) -> Content
    
    private var state: Default<Set<T>>
    
    init(key: Defaults.Key<Set<T>>, value: T, @ViewBuilder label: @escaping (T) -> Content) {
      self.key = key
      self.value = value
      self.label = label
      
      state = Default.init(key)
    }
    
    var body: some View {
      SwiftUI.Toggle(isOn: toggleFlagBinding(state.projectedValue, has: value)) {
        label(value)
      }
    }
    
    func toggleFlagBinding(_ source: Binding<Set<T>>, has value: T) -> Binding<Bool> {
      .contains(source, has: value).onChange { val in
        source.wrappedValue.toggleExistence(value, shouldExist: val)
      }
    }
  }
}
