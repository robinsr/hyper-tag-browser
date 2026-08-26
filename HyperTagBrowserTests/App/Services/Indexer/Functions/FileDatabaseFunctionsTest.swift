// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble
import UniformTypeIdentifiers

@testable import HyperTagBrowser


@Suite("FileDatabaseFunctions", .tags(.indexer))
struct FileDatabaseFunctionsTest {

  let tempFile: URL

  init() throws {
    let dir = FileManager.default.temporaryDirectory
    tempFile = dir.appendingPathComponent("uitest-\(UUID().uuidString).jpg")
    FileManager.default.createFile(atPath: tempFile.path, contents: Data([0xFF, 0xD8, 0xFF]))
  }

  // MARK: - fileExists

  @Test("fileExists returns true for existing file")
  func test_file_exists_true() {
    let result = FilesDBFunctions.execFileExists([tempFile])
    expect(result as? Bool).to(beTrue())
  }

  @Test("fileExists returns false for nonexistent path")
  func test_file_exists_false() {
    let nonexistentURL = FileManager.default.temporaryDirectory.appendingPathComponent("does-not-exist-\(UUID().uuidString).txt")
    let result = FilesDBFunctions.execFileExists([nonexistentURL])
    expect(result as? Bool).to(beFalse())
  }

  @Test("fileExists returns nil for wrong type input")
  func test_file_exists_nil_for_wrong_type() {
    let result = FilesDBFunctions.execFileExists([Optional<URL>.none])
    expect(result).to(beNil())
  }

  // MARK: - fileExistsIn

  @Test("fileExistsIn returns true when file exists in folder")
  func test_file_exists_in_true() {
    let folderURL = FileManager.default.temporaryDirectory
    let fileName = tempFile.lastPathComponent
    let result = FilesDBFunctions.execFileExistsIn([folderURL, fileName])
    expect(result as? Bool).to(beTrue())
  }

  @Test("fileExistsIn returns false for unknown filename in folder")
  func test_file_exists_in_false() {
    let folderURL = FileManager.default.temporaryDirectory
    let unknownFileName = "does-not-exist-\(UUID().uuidString).txt"
    let result = FilesDBFunctions.execFileExistsIn([folderURL, unknownFileName])
    expect(result as? Bool).to(beFalse())
  }

  // MARK: - fileSize

  @Test("fileSize returns a non-nil value for existing file")
  func test_file_size_returns_value() {
    let result = FilesDBFunctions.execFileSize([tempFile])
    expect(result).notTo(beNil())
    expect(result as? NSNumber).to(beGreaterThan(NSNumber(value: 0)))
  }

  @Test("fileSize returns nil for nonexistent path")
  func test_file_size_nil_for_nonexistent() {
    let nonexistentURL = FileManager.default.temporaryDirectory.appendingPathComponent("does-not-exist-\(UUID().uuidString).txt")
    let result = FilesDBFunctions.execFileSize([nonexistentURL])
    expect(result).to(beNil())
  }

  // MARK: - fileContentType

  @Test("fileContentType returns a non-nil value for existing JPEG file")
  func test_file_content_type_returns_value() {
    let result = FilesDBFunctions.execFileContentType([tempFile])
    expect(result).notTo(beNil())
    expect(result as? UTType).to(equal(UTType.jpeg))
  }

  @Test("fileContentType returns .item fallback for nonexistent path")
  func test_file_content_type_nonexistent_file() {
    let nonexistentJPEG = FileManager.default.temporaryDirectory.appendingPathComponent("nonexistent-\(UUID().uuidString).jpg")
    let result = FilesDBFunctions.execFileContentType([nonexistentJPEG])
    expect(result as? UTType).to(equal(UTType.item))
  }

  // MARK: - conformsTo

  @Test("conformsTo returns true when UTType conforms to another")
  func test_conforms_to_true() {
    let result = FilesDBFunctions.execConformsTo([UTType.jpeg, UTType.image])
    expect(result as? Bool).to(beTrue())
  }

  @Test("conformsTo returns false when UTType does not conform")
  func test_conforms_to_false() {
    let result = FilesDBFunctions.execConformsTo([UTType.pdf, UTType.image])
    expect(result as? Bool).to(beFalse())
  }

  // MARK: - fileConformsTo

  @Test("fileConformsTo returns true for file conforming to type")
  func test_file_conforms_to_true() {
    let result = FilesDBFunctions.execFileConformsTo([tempFile, UTType.image])
    expect(result as? Bool).to(beTrue())
  }

  @Test("fileConformsTo returns false for file not conforming to type")
  func test_file_conforms_to_false() {
    let result = FilesDBFunctions.execFileConformsTo([tempFile, UTType.pdf])
    expect(result as? Bool).to(beFalse())
  }
}
