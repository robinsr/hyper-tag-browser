// created on 4/3/25 by robinsr

import Foundation
import System


/**
 * Just a container for a ordered set of string-like components intended to be dot-separated when formatted
 */
struct DotPath {
    // typealias Component = any ExpressibleByStringLiteral
  typealias Component = any ExpressibleByStringInterpolation
  
  var components: [Component]
  
  init(_ components: [Component] = []) {
    self.components = components
  }
  
  init(_ components: Component...) {
    self.components = components
  }
  
  private func format(separator sep: Character = ".") -> String {
    components
      .map { "\($0)" }
      .filter { !$0.isEmpty }
      .joined(separator: "\(sep)")
      .replacingOccurrences(of: String(repeating: sep, count: 2), with: "\(sep)")
  }
  
  var string: String { format() }
  
  func joined(separator sep: Character) -> String {
    format(separator: sep)
  }
  
  var filepath: FilePath { FilePath(string) }
  
  mutating func append(_ component: Component) {
    components.append(component)
  }
  
  func appending(_ component: Component) -> DotPath {
    DotPath(components + [component])
  }
}


extension DotPath {
  static func joined(_ components: Component...) -> String {
    DotPath(components).string
  }
  
  static func +(lhs: DotPath, rhs: Component) -> DotPath {
    lhs.appending(rhs)
  }
  
  static func +(lhs: DotPath, rhs: DotPath) -> DotPath {
    DotPath(lhs.components + rhs.components)
  }
}

extension DotPath: CustomStringConvertible {
  var description: String { self.string }
}

extension DotPath: CustomDebugStringConvertible {
  var debugDescription: String { "DotPath(\(self.string))" }
}

extension DotPath: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
  
  /**
   * Enables initialization from a string literal, splitting it by '.' to create components.
   *
   * Example:
   * ```swift
   * let path: DotPath = "com.example.module.submodule"
   * print(path.components) // ["com", "example", "module", "submodule"]
   * ```
   */
  init(stringLiteral value: String) {
    self.init(value.split(separator: ".").map { String($0) })
  }
}


extension Collection where Element == DotPath.Component {
  
  /**
   * Converts a Collection of String-like components to a DotPath.
   *
   * ```swift
   * let base = ["a", "b", c"].asDotPath
   * let pathX = base.appending("x").string
   * print(pathX) // "a.b.c.x"
   */
  var asDotPath: DotPath {
    DotPath(Array(self))
  }
  
  /**
   * Converts a String array to a dotpath
   *
   * ```swift
   * print(["a", "b", "c"].dotPath) // "a.b.c"
   * ```
   */
  var dotPath: String {
    DotPath(Array(self)).string
  }
}
