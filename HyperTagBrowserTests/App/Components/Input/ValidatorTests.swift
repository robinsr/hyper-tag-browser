// created on 2/1/25 by robinsr

import Foundation
import Testing
import Nimble

@testable import TaggedFileBrowser


@Suite("Components : Input : TextFieldModel")
struct TextFieldModelTests {
  
  typealias Constraint = TextFieldModel.Constraint
  
  enum TestCase {
    case valid(String)
    case invalid(String, Constraint)
    
    var input: String {
      switch self {
      case .valid(let input): return input
      case .invalid(let input, _): return input
      }
    }
    
    var isValid: Bool {
      switch self {
      case .valid: return true
      case .invalid: return false
      }
    }
    
    var validationMessage: String? {
      switch self {
      case .valid: return nil
      case .invalid(_, let constraint): return constraint.message
      }
    }
    
    func failureMessage(_ expected: String) -> String {
      switch self {
      case .valid(let input): return "Expected \(expected) for valid input: '\(input)'"
      case .invalid(let input, _): return "Expected \(expected) for invalid input: '\(input)'"
      }
    }
    
    static let presence: [Self] = [
      .invalid("",      Constraint.presence),
      .invalid(" ",     Constraint.presence),
      .invalid("     ", Constraint.presence),
      .valid("a"),
    ]
    
    static let filenames: [Self] = [
      .invalid("",      Constraint.presence),
      .invalid(" ",     Constraint.presence),
      .invalid("     ", Constraint.presence),
      .invalid("lo:rem.txt", Constraint.disallow_colon),
      .invalid(" :lorem.txt ", Constraint.disallow_colon),
      .invalid("lo/rem.txt", Constraint.disallow_forwardslash),
      .invalid("/lorem.txt", Constraint.disallow_forwardslash),
      .invalid("lorem.txt/", Constraint.disallow_forwardslash),
      .invalid("loremtxt", Constraint.filename_extension),
      .valid("a.txt"),
      .valid("[asdf123]  !@#$%^&*  - ___ {}{}{}.txt"),
      .valid("filename.foo.bar.baz.txt"),
    ]
  }
  
  
  @Suite("Validate")
  struct ValidateTests {
    
    @Test("Validate presence", arguments: TestCase.presence)
    func test_validate_presence(testing: TestCase) {
      let model = TextFieldModel(validate: [.presence])
      model.rawValue = testing.input
      
      if testing.isValid {
        expect(model.isValid)
          .to(equal(true), description: testing.failureMessage("isValid to be true"))
        
        expect(model.error)
          .to(beNil(), description: testing.failureMessage("nil validation message"))
      } else {
        expect(model.isValid)
          .to(equal(false), description: testing.failureMessage("isValid to be false"))
        
        expect(model.error)
          .to(equal(testing.validationMessage), description: testing.failureMessage("non-nil validation message"))
      }
    }
    
    @Test("Validate filenames", arguments: TestCase.filenames)
    func test_validate_filenames(testing: TestCase) {
      let model = TextFieldModel(validate: [.presence, .disallow_colon, .disallow_forwardslash, .filename_extension])
      model.rawValue = testing.input
      
      if testing.isValid {
        expect(model.isValid)
          .to(equal(true), description: testing.failureMessage("isValid to be true"))
        
        expect(model.error)
          .to(beNil(), description: testing.failureMessage("nil validation message"))
      } else {
        expect(model.isValid)
          .to(equal(false), description: testing.failureMessage("isValid to be false"))
        
        expect(model.error)
          .to(equal(testing.validationMessage), description: testing.failureMessage("non-nil validation message"))
      }
    }
  }
}
