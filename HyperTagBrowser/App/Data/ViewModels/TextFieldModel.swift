// created on 11/7/24 by robinsr

import Regex
import SwiftUI

@MainActor
@Observable
class TextFieldModel {

  /// A set of validation constraints to apply to the text input.
  private(set) var validations: [UserInputConstraint] = []

  /// The default value to use when the field is reset.
  private(set) var initialValue: String = ""
  
  /// Stores any validation error message that occurs during input validation. Is `nil` if text input is valid.
  var error: String? = nil

  /// The TextField's current raw value. Use `TextFieldModel.rawValue` as a binding source.
  var rawValue: String = "" {
    didSet {
      _valuePublisher.update(rawValue)
      error = validations.compactMap { $0.validate(rawValue.trimmed) }.first
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
    validate: [UserInputConstraint] = [],
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
    validations.compactMap { $0.validate(rawValue.trimmed) }
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
  
  var isFilled: Bool {
    _publishedValue.isEmpty == false
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
  
  func reset() {
    rawValue = initialValue
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
}


