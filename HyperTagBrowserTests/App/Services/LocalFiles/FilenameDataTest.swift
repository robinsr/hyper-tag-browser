// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("FilenameData", .tags(.dataModel))
struct FilenameDataTest {

  // MARK: - filename

  @Test("filename returns the last path component of the URL")
  func test_filename_from_url() {
    let url = URL(fileURLWithPath: "/photos/sunset {landscape,nature}.jpg")
    let data = FilenameData(fileURL: url)
    expect(data.filename).to(equal("sunset {landscape,nature}.jpg"))
  }

  // MARK: - inBracesValues

  @Test("inBracesValues extracts comma-separated values from curly braces")
  func test_in_braces_values() {
    let url = URL(fileURLWithPath: "/photos/image {alpha,beta,gamma}.jpg")
    let data = FilenameData(fileURL: url)
    expect(data.inBracesValues).to(equal(["alpha", "beta", "gamma"]))
  }

  @Test("inBracesValues returns empty array when no braces present")
  func test_in_braces_values_none() {
    let url = URL(fileURLWithPath: "/photos/plain-image.jpg")
    let data = FilenameData(fileURL: url)
    expect(data.inBracesValues).to(beEmpty())
  }

  // MARK: - inBracketValues

  @Test("inBracketValues extracts comma-separated values from square brackets")
  func test_in_bracket_values() {
    let url = URL(fileURLWithPath: "/photos/image [tag1,tag2].jpg")
    let data = FilenameData(fileURL: url)
    expect(data.inBracketValues).to(equal(["tag1", "tag2"]))
  }

  @Test("inBracketValues returns empty array when no brackets present")
  func test_in_bracket_values_none() {
    let url = URL(fileURLWithPath: "/photos/plain-image.jpg")
    let data = FilenameData(fileURL: url)
    expect(data.inBracketValues).to(beEmpty())
  }

  // MARK: - inParenthesesValues

  @Test("inParenthesesValues extracts comma-separated values from parentheses")
  func test_in_parentheses_values() {
    let url = URL(fileURLWithPath: "/photos/image (a,b).jpg")
    let data = FilenameData(fileURL: url)
    expect(data.inParenthesesValues).to(equal(["a", "b"]))
  }

  // MARK: - valid

  @Test("valid returns true when filename contains curly braces")
  func test_valid_with_braces() {
    let url = URL(fileURLWithPath: "/photos/image {tag}.jpg")
    let data = FilenameData(fileURL: url)
    expect(data.valid).to(beTrue())
  }

  @Test("valid returns false when filename has no curly braces")
  func test_valid_without_braces() {
    let url = URL(fileURLWithPath: "/photos/plain.jpg")
    let data = FilenameData(fileURL: url)
    expect(data.valid).to(beFalse())
  }

  // MARK: - static validate

  @Test("validate returns true for string with curly braces")
  func test_static_validate_with_braces() {
    expect(FilenameData.validate("photo {landscape}.jpg")).to(beTrue())
  }

  @Test("validate returns false for string without curly braces")
  func test_static_validate_without_braces() {
    expect(FilenameData.validate("photo.jpg")).to(beFalse())
  }
}
