// Created on 9/15/24 by robinsr

import Foundation
import SwiftUI
import OrderedCollections
import Regex


struct FilenameData {
  let fileURL: URL
  
  var filename: String {
    fileURL.lastPathComponent
  }
  
  var inBracketValues: [String] {
    (Patterns.bracketed.match(against: filename) ?? "")
      .split(separator: ",")
      .map { String($0) }
  }

  var inBracesValues: [String] {
    (Patterns.braced.match(against: filename) ?? "")
      .split(separator: ",")
      .map { String($0) }
  }
  
  var inParenthesesValues: [String] {
    (Patterns.parentheses.match(against: filename) ?? "")
      .split(separator: ",")
      .map { String($0) }
  }
  
  var valid: Bool {
    Self.validate(filename)
  }
  
  func mapTo(_ keypath: KeyPath<FilenameData, [String]>, type: FilteringTag.TagType) -> [FilteringTag] {
    self[keyPath: keypath].compactMap {
      FilteringTag(rawValue: $0, type: type)
    }
  }
  
  static func validate(_ input: String) -> Bool {
    return Patterns.braced.match(against: input) != nil
  }
  
  
  enum Patterns {
      /// Matches a string enclosed in square brackets
    case bracketed
      /// Matches a string enclosed in parentheses
    case parentheses
      /// Matches a string enclosed in curly braces
    case braced
     /// Matches whitespace between non-whitespace characters
    case innerWhitespace
    
    var pattern: String {
      switch self {
      case .bracketed: return #"\[([^\]]+)\]"#
      case .parentheses: return #"\(([^\)]+)\)"#
      case .braced: return #"\{([^\}]+)\}"#
      case .innerWhitespace: return #"\w([\W_]+)\w"#
      }
    }
    
    var regex: Regex {
      return try! Regex(string: pattern)
    }
    
    func match(against: String) -> String? {
      let result = regex.firstMatch(in: against)
      if let capture = result?.captures[0] { return capture }
      return nil
    }
  }
}
