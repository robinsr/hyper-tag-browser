// created on 11/7/24 by robinsr

import Regex
import SwiftUI

@Observable
class TextFieldModel {

  /// A set of validation constraints to apply to the text input.
  private(set) var validations: [Constraint] = []

  /// The default value to use when the field is reset.
  private(set) var initialValue: String = ""
  
  /// Stores any validation error message that occurs during input validation. Is `nil` if text input is valid.
  var error: String? = nil

  /// The TextField's current raw value. Use `TextFieldModel.rawValue` as a binding source.
  var rawValue: String = "" {
    didSet {
      _valuePublisher.update(rawValue)
    }
  }

  /// The readable output of the `TextFieldModel`, debounced and trimmed.
  //private(set) var value: Binding<String>
  
  private var _publishedValue: String = ""
  private var _valuePublisher = ValuePublisher(initialValue: "")
  private var _publisherCancellable: AnyCancellable?
  
  var value: String {
    get { _publishedValue }
    set {
      // Update the raw value directly from the binding
      rawValue = newValue.trimmed
    }
  }

  init(
    initial value: String = "",
    validate: [Constraint] = [],
    updateInterval duration: Duration = .milliseconds(200)
  ) {
    self.validations = validate
    self.initialValue = value.trimmed
    self.rawValue = value.trimmed
    self.error = nil
    
    self._publisherCancellable = self._valuePublisher.$textValue
      .debounce(for: .nanoseconds(Int(duration.nanoseconds)), scheduler: DispatchQueue.main)
      .sink { [weak self] newValue in
        self?._publishedValue = newValue.trimmed
      }
  }


  var validationMessages: [String] {
    validations.compactMap { $0.validate(_publishedValue) }
  }

  var isValid: Bool {
    validationMessages.isEmpty
  }

  var isInvalid: Bool {
    validationMessages.notEmpty
  }

  var hasError: Bool {
    self.error != nil
  }
  
  var count: Int {
    _publishedValue.count
  }

  var isEmpty: Bool {
    _publishedValue.isEmpty
  }

  /**
   * Reads the current value, then resets the value to an empty string
   */
  func read(ignoreValidations ignore: Bool = false) -> String {
    let readVal = self.copy(ignoreValidations: ignore) // read current value
    
    self.reset(to: self.initialValue) // reset to initial value
    
    return readVal
  }

  /**
   * Reads the current value, leaving the raw value unchanged.
   */
  func copy(ignoreValidations ignore: Bool = false) -> String {
    if !ignore && self.validationMessages.notEmpty {
      self.error = self.validationMessages.first
      return ""
    }

    return self._publishedValue.trimmed
  }

  /**
   * Resets the model to its initial state, clearing the raw value and error
   */
  func reset(to newVal: String) {
    rawValue = newVal.trimmed
    error = nil
  }

  
  /// Publishes the current text value, enabling debounced updates for UI bindings.
  class ValuePublisher {
    @Published private(set) var textValue: String

    init(initialValue: String) {
      self.textValue = initialValue.trimmed
    }
    
    func update(_ newValue: String) {
      textValue = newValue.trimmed
    }
  }

  
  /**
   * Defines validation constraints for the `TextFieldModel`.
   */
  enum Constraint {
    case require(_ pattern: String, message: String)
    case reject(_ pattern: String, message: String)
    case satisfies(_ closure: (String) -> Bool, message: String)

    /// Validates that the field is not empty
    static let presence: Constraint = .satisfies(
      {
        !$0.trimmed.isEmpty
      }, message: "This field cannot be empty")

    /// Forward-slashes are not allowed at the OS level
    static let disallow_forwardslash: Constraint = .reject(
      #".*\/.*"#, message: "Filenames cannot contain '/'")

    /// Colons are allowed, but this breaks with Finder conventions
    static let disallow_colon: Constraint = .reject(
      #".*:.*"#, message: "Filenames cannot contain ':'")

    /// Validates filename has an file extension
    static let filename_extension: Constraint = .require(
      #"^.*\.[\d\w]+$"#, message: "Filenames must have a file extension")

    var message: String {
      switch self {
        case .satisfies(_, let message), .require(_, let message), .reject(_, let message):
          return message
      }
    }

    func isValidInput(_ value: String) -> Bool {
      switch self {
        case .satisfies(let closure, _):
          return closure(value)
        case .require(let pattern, _):
          return parsePattern(pattern).matches(value)
        case .reject(let pattern, _):
          return parsePattern(pattern).matches(value) == false
      }
    }

    func validate(_ value: String) -> String? {
      isValidInput(value) ? nil : message
    }

    private func parsePattern(_ pattern: String) -> Regex {
      guard let regex = try? Regex(string: pattern) else {
        fatalError("Invalid validation pattern supplied: \(pattern)")
      }

      return regex
    }
  }
}
