// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("FilePredicates", .tags(.dataModel))
struct FilePredicatesTest {

  // MARK: - FSPredicates.isHomeDir

  @Test("isHomeDir returns true for home directory URL")
  func test_is_home_dir_true() {
    let home = URL.homeDirectory
    expect(FSPredicates.isHomeDir(home)).to(beTrue())
  }

  @Test("isHomeDir returns false for a subdirectory of home")
  func test_is_home_dir_false_for_subdir() {
    let subdir = URL.homeDirectory.appending(path: "Documents")
    expect(FSPredicates.isHomeDir(subdir)).to(beFalse())
  }

  @Test("isHomeDir returns false for a file URL")
  func test_is_home_dir_false_for_file() {
    let file = URL.homeDirectory.appending(path: "file.txt")
    expect(FSPredicates.isHomeDir(file)).to(beFalse())
  }

  // MARK: - FSPredicates.isAboveHomeDir

  @Test("isAboveHomeDir returns true for parent of home directory")
  func test_is_above_home_dir_true() {
    let parent = URL.homeDirectory.deletingLastPathComponent()
    expect(FSPredicates.isAboveHomeDir(parent)).to(beTrue())
  }

  @Test("isAboveHomeDir returns false for home directory itself")
  func test_is_above_home_dir_false_for_home() {
    expect(FSPredicates.isAboveHomeDir(URL.homeDirectory)).to(beFalse())
  }

  @Test("isAboveHomeDir returns false for a subdir of home")
  func test_is_above_home_dir_false_for_subdir() {
    let subdir = URL.homeDirectory.appending(path: "Documents")
    expect(FSPredicates.isAboveHomeDir(subdir)).to(beFalse())
  }

  // MARK: - URL.conforms(to:)

  @Test("URL.conforms(to:) returns true when predicate matches")
  func test_url_conforms_matching_predicate() {
    let home = URL.homeDirectory
    expect(home.conforms(to: FSPredicates.isHomeDir)).to(beTrue())
  }

  @Test("URL.conforms(to:) returns false when predicate does not match")
  func test_url_conforms_non_matching_predicate() {
    let subdir = URL.homeDirectory.appending(path: "Documents")
    expect(subdir.conforms(to: FSPredicates.isHomeDir)).to(beFalse())
  }
}
