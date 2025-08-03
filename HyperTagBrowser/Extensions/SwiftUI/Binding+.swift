// created on 9/27/24 by robinsr

import SwiftUI

extension Binding {
  
  /**
   * Creates a read-only binding
   */
  static func readOnly(_ value: Value) -> Binding {
    Binding(get: { value }, set: { _ in })
  }
  
  static func valueNotNil(_ value: Optional<Value>) -> Binding<Bool> {
    Binding<Bool>(get: { value != nil }, set: { _ in })
  }
  
  /**
   Returns a binding that will call a handler function after a new value is set
   
   Usage:
   ```
   @State var value: Int
   
   func onValChanged(newValue: Int) {
       print("Value changed to \(newValue)")
   }
   
   var body: some View {
       TextField("Enter a value", value: $value.onChange(onValChanged))
   }
   ```
   */
  func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
    Binding(
      get: { self.wrappedValue },
      set: { newValue in
        self.wrappedValue = newValue
        handler(newValue)
      }
    )
  }
  
  
  /**
   Returns a non-optional binding from an optional binding
   
    Usage:
    
   ```swift
   @State var searchService: SearchService
   
   var body: some View {
       TextField("Query", text: $searchService.query.withDefault(""))
   }
    ```
   */
  func withDefault<T>(_ defaultValue: T) -> Binding<T> where Value == Optional<T> {
    Binding<T>(
      get: { self.wrappedValue ?? defaultValue },
      set: { self.wrappedValue = $0 }
    )
  }
  
    /// Creates a binding with a default value
  static func withDefault(_ defaultValue: Value) -> Binding<Value> {
    let _value = State(initialValue: defaultValue)
    
    return Binding(
      get: { _value.wrappedValue },
      set: { _value.wrappedValue = $0 }
    )
  }
  
  
  func map<T>(_ transform: @escaping (Value) -> T) -> Binding<T> {
    Binding<T>(
      get: { transform(self.wrappedValue) },
      set: { _ in }
    )
  }

  
  /**
   Returns a `Bool` binding that is true when the value is equal to the given value
   
   Usage:
   
   ```swift
   @State var value: Int
   
   var body: some View {
       DisclosureGroup("Shown if value = 5", isExpanded: .equals($value, eq: 5)) {
         ContentView()
       }
   }
   ```
   */
  static func equals<T: Equatable>(_ source: Binding<T>, eq equalTo: T) -> Binding<Bool> {
    Binding<Bool>(
      get: { source.wrappedValue == equalTo },
      set: { _ in  }
    )
  }
  
  /**
   Returns a `Bool` binding from a `Optional<Bool>` binding that is false when the optional value is nil
   */
  static func notNil<T>(_ source: Binding<Optional<T>>) -> Binding<Bool> {
    Binding<Bool>(
      get: { source.wrappedValue != nil },
      set: { _ in }
    )
  }
  
  
  
  /**
    Returns a `Bool` binding that is true when the value is contained in the given array
   
    Usage:
      
    ```swift
    @State var shownItems = [1, 2, 3]
    var body: some View {
      DisclosureGroup("", isExpanded: .contains($shownItems, has: 4)) {
        Text("4 is in shownItems")
      }
    }
    ```
   */
  static func contains<T: Equatable>(_ source: Binding<[T]>, has item: T) -> Binding<Bool> {
    Binding<Bool>(
      get: { source.wrappedValue.contains(item) },
      set: { shouldContain in
        if shouldContain {
          source.wrappedValue.append(item)
        } else {
          source.wrappedValue.removeAll { $0 == item }
        }
      }
    )
  }
  
  static func contains<T: Equatable>(_ source: Binding<Set<T>>, has item: T) -> Binding<Bool> {
    Binding<Bool>(
      get: { source.wrappedValue.contains(item) },
      set: { shouldContain in
        source.wrappedValue.toggleExistence(item, shouldExist: shouldContain)
      }
    )
  }
  
  /**
   Aggregates multiple `Bool` bindings into a single `Bool` binding
   */
  static func any(_ sources: Binding<Bool>...) -> Binding<Bool> {
    Binding<Bool>(
      get: {
        sources.map { $0.wrappedValue }.contains(true)
      },
      set: { _ in }
    )
  }
}


extension Binding where Value: SetAlgebra, Value.Element: Hashable {
  
  /**
   Returns a `Bool` binding that is true when the value is contained in the given array
   */
  func contains(_ item: Value.Element) -> Binding<Bool> {
    Binding<Bool>(
      get: { self.wrappedValue.contains(item) },
      set: { shouldContain in
        if shouldContain {
          self.wrappedValue.insert(item)
        } else {
          self.wrappedValue.remove(item)
        }
      }
    )
  }
}
