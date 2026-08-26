// created on 12/27/25 by robinsr

import Regex


/**
 * Defines validation constraints for the `TextFieldModel`.
 */
struct UserInputConstraint: Sendable {
  typealias StringTestFn = @Sendable (String) -> Bool
  
  let message: String
  
  let testFn: @Sendable (String) -> Bool
  
  init(message: String) {
    self.message = message

    self.testFn = { _ in
      return true
    }
  }

  init(message: String, testFn: @escaping StringTestFn) {
    self.message = message
    self.testFn = testFn
  }
  
  init(message: String, pattern: String, expected: Bool = true) {
    self.message = message
    
    guard let regex = try? Regex(string: pattern) else {
      fatalError("Invalid validation pattern supplied: \(pattern)")
    }
    
    self.testFn = {
      return regex.matches($0) == expected
    }
  }
  
  func validate(_ value: String) -> String? {
    self.testFn(value) ? nil : self.message
  }

  private func parsePattern(_ pattern: String) -> Regex {
    guard let regex = try? Regex(string: pattern) else {
      fatalError("Invalid validation pattern supplied: \(pattern)")
    }

    return regex
  }
  
  static func require(_ message: String, pattern: String) -> Self {
    Self.init(message: message, pattern: pattern)
  }
  
  static func reject(_ message: String, pattern: String) -> Self {
    Self.init(message: message, pattern: pattern, expected: false)
  }
  
  static func satisfies(_ message: String, test: @escaping StringTestFn) -> Self {
    Self.init(message: message, testFn: test)
  }

  /// Validates that the field is not empty
  static let presence: Self = .satisfies("This field cannot be empty") { !$0.trimmed.isEmpty }
  
  /// Forward-slashes are not allowed at the OS level
  static let disallow_forwardslash: Self = .reject("Filenames cannot contain '/'", pattern: #".*\/.*"#)

  /// Colons are allowed, but this breaks with Finder conventions
  static let disallow_colon: Self = .reject("Filenames cannot contain ':'", pattern: #".*:.*"#)

  /// Validates filename has an file extension
  static let filename_extension: Self = .require("Filenames must have a file extension", pattern: #"^.*\.[\d\w]+$"#)
}
