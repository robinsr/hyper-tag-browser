// created on 10/25/24 by robinsr

import Foundation
import GrammaticalNumber
import Regex


extension String {
  func pluralized(using count: Int) -> String {
    if count != 1 {
      return self.pluralized()
    } else {
      return self.singularized()
    }
  }
}


  // MARK: - Pluralization

extension String.StringInterpolation {
  
  private var quantityOfStyle: IntegerFormatStyle<Int> {
    IntegerFormatStyle() // "123,456,789"
  }
  
  /**
    Appends a pluralized term to the string interpolation.
    
    ```
    String("item", pluralize: 1) // "item"
    String("item", pluralize: 2) // "items"
    ```
   */
  mutating func appendInterpolation(_ term: String, pluralizeWith count: Int) {
    appendLiteral(term.pluralized(using: count))
  }
  
  
  /// Appends "Num of Y" where Y is plurailized if needed.
  /// ```swift
  /// String("apple", qty: 123) // "123 apples"
  /// ```
  mutating func appendInterpolation(_ term: String, qty count: Int) {
    let quantifier = count.formatted(quantityOfStyle)
    let pluralized = term.pluralized(using: count)
    
    appendInterpolation("\(quantifier) \(pluralized)")
  }
 
  /// Appends "Num of Y" where Y is plurailized if needed.
  /// ```swift
  /// String("apple", counting: 123) // "123 apples"
  /// ```
  @available(*, deprecated, renamed: "appendInterpolation(_:qty:)", message: "use `appendInterpolation(_:qty:)` instead")
  mutating func appendInterpolation(_ term: String, counting count: Int) {
    appendInterpolation("\(term, qty: count)")
  }
  
  /// Appends "Num of Y" where Y is plurailized if needed.
  /// ```swift
  /// String(quantity: 123, of: "apple") // "123 apples"
  /// ```
  @available(*, deprecated, renamed: "appendInterpolation(_:qty:)", message: "use `appendInterpolation(_:qty:)` instead")
  mutating func appendInterpolation(quantity count: Int, of term: String) {
    appendInterpolation("\(term, qty: count)")
  }

  /// Appends "Num of Y" where Y is plurailized if needed.
  /// ```swift
  /// String(qty: 123, of: "apple") // "123 apples"
  /// ```
  @available(*, deprecated, renamed: "appendInterpolation(_:qty:)", message: "use `appendInterpolation(_:qty:)` instead")
  mutating func appendInterpolation(qty count: Int, of term: String) {
    appendInterpolation("\(term, qty: count)")
  }
}


extension String.StringInterpolation {
  
  /**
  Interpolate the value by unwrapping it, and if `nil`, use the given default string.

  ```
  // This doesn't work as you can only use nil coalescing in interpolation with the same type as the optional
  "foo \(optionalDouble ?? "none")

  // Now you can do this
  "foo \(optionalDouble, default: "none")
  ```
  */
  public mutating func appendInterpolation(_ value: Any?, default defaultValue: String) {
    if let value {
      appendInterpolation(value)
    } else {
      appendLiteral(defaultValue)
    }
  }

  /**
  Interpolate the value by unwrapping it, and if `nil`, use `"nil"`.

  ```
  // This doesn't work as you can only use nil coalescing in interpolation with the same type as the optional
  "foo \(optionalDouble ?? "nil")

  // Now you can do this
  "foo \(describing: optionalDouble)
  ```
  */
  public mutating func appendInterpolation(describing value: Any?) {
    if let value {
      appendInterpolation(value)
    } else {
      appendLiteral("nil")
    }
  }
  
  
  @available(*, deprecated, message: "use `(value, default:)` instead")
  mutating func appendInterpolation(string val: String?, default: String = "[nil]") {
    if let val = val {
      appendInterpolation("\"\(val)\"")
    } else {
      appendLiteral(`default`)
    }
  }

  
  enum TruncDirection {
    case front
    case back
    case middle
  }
    
  /**
   Does basic string truncation.
   
   ```
   String("Hello, World!", truncate: 5) // "Hello..."
   String("Hello, World!", truncate: 5, from: .front) // "...World!"
    String("Hello, World!", truncate: 5, from: .middle) // "He...rld!"
    ```
   */
  mutating func appendInterpolation<T>(_ value: T,
                                       truncate length: Int,
                                       from: TruncDirection = .back
  ) where T : CustomStringConvertible {
    let value = value.description
    
    switch from {
    case .front:
      appendLiteral("...")
      appendLiteral(String(value.suffix(length)))
    case .back:
      appendLiteral(String(value.prefix(length)))
      appendLiteral("...")
    case .middle:
      appendLiteral(String(value.prefix(length/2)))
      appendLiteral("...")
      appendLiteral(String(value.suffix(length/2)))
    }
  }
  
  /**
   truncates a string to a maximum length.
   
   ```swift
   // equivalent of
   let truncated = "\(value, truncate: N, from: .back)"
   ```
   */
  mutating func appendInterpolation(_ value: String, max: Int) {
    appendInterpolation(value, truncate: max, from: .back)
  }
  
  
  /**
   Removes leading parts of a URL path above the user directory.
   
   ```
   String(homeURL: "/Users/bill/Downloads") // "Downloads"
   ```
   */
  mutating func appendInterpolation(homeURL url: URL) {
    if url.path.hasPrefix(NSHomeDirectory()) {
      let shortenedPath = url.path.dropFirst(NSHomeDirectory().count)
      appendInterpolation("~\(shortenedPath)")
    } else {
      appendLiteral(url.filepath.string)
    }
  }
  
  /**
   Removes leading parts of a URL path from a base URL
   
   ```
   let url = URL(fileURLWithPath: "/Users/bill/files/docs/folders/folder/target")
   
   String(url, relativeTo: "/Users/bill/files") // "./docs/folders/folder/target"
   ```
   */
  mutating func appendInterpolation(_ url: URL, relativeTo base: URL) {
    if url.path.hasPrefix(base.path) {
      let shortenedPath = url.path.dropFirst(base.path.count)
      appendInterpolation(".\(shortenedPath)")
    } else {
      appendLiteral(url.filepath.string)
    }
  }
  
  
  /**
   * Appends a 3 digit floating point number to the string interpolation.
   *
   * ```swift
   * let brightness: CGFloat = 0.5
   * String(brightness: brightness) // "0.500"
   * ```
   */
  mutating func appendInterpolation(brightness: CGFloat) {
    appendLiteral(String(format: "%1.3f", brightness))
  }

  
  /**
   * Appends the string representation of a ``KeyBinding``.
   */
  mutating func appendInterpolation(shortcut: KeyBinding) {
    appendInterpolation(shortcut.asCharacters)
  }
}
