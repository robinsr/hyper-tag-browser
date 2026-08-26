// created on 8/26/26 by robinsr

import Foundation
import Testing
import Nimble
import UniformTypeIdentifiers

@testable import HyperTagBrowser

@Suite("ContentTypeGrouping", .tags(.dataModel))
struct ContentTypeGroupingTest {

  // MARK: - filetypes membership

  @Test("images group filetypes contains UTType.jpeg")
  func test_images_filetypes_contains_jpeg() {
    expect(ContentTypeGroup.images.filetypes).to(contain(UTType.jpeg))
  }

  @Test("images group filetypes contains UTType.image")
  func test_images_filetypes_contains_image() {
    expect(ContentTypeGroup.images.filetypes).to(contain(UTType.image))
  }

  @Test("folders group filetypes contains UTType.folder")
  func test_folders_filetypes_contains_folder() {
    expect(ContentTypeGroup.folders.filetypes).to(contain(UTType.folder))
  }

  @Test("video group filetypes contains UTType.video")
  func test_video_filetypes_contains_video() {
    expect(ContentTypeGroup.video.filetypes).to(contain(UTType.video))
  }

  @Test("empty group has no filetypes")
  func test_empty_filetypes_is_empty() {
    expect(ContentTypeGroup.empty.filetypes).to(beEmpty())
  }

  // MARK: - allows(filetype:)

  @Test("images allows jpeg")
  func test_images_allows_jpeg() {
    expect(ContentTypeGroup.images.allows(filetype: .jpeg)).to(beTrue())
  }

  @Test("images does not allow pdf")
  func test_images_does_not_allow_pdf() {
    expect(ContentTypeGroup.images.allows(filetype: .pdf)).to(beFalse())
  }

  @Test("folders allows folder type")
  func test_folders_allows_folder() {
    expect(ContentTypeGroup.folders.allows(filetype: .folder)).to(beTrue())
  }

  @Test("empty allows nothing")
  func test_empty_allows_nothing() {
    expect(ContentTypeGroup.empty.allows(filetype: .jpeg)).to(beFalse())
    expect(ContentTypeGroup.empty.allows(filetype: .folder)).to(beFalse())
  }

  // MARK: - contains(member:)

  @Test("composite 'user' group contains 'folders'")
  func test_user_contains_folders() {
    expect(ContentTypeGroup.user.contains(member: .folders)).to(beTrue())
  }

  @Test("non-composite 'images' group does not contain 'video'")
  func test_images_does_not_contain_video() {
    expect(ContentTypeGroup.images.contains(member: .video)).to(beFalse())
  }

  // MARK: - isCompositeType

  @Test("'all' is a composite type")
  func test_all_is_composite() {
    expect(ContentTypeGroup.all.isCompsiteType).to(beTrue())
  }

  @Test("'images' is not a composite type")
  func test_images_is_not_composite() {
    expect(ContentTypeGroup.images.isCompsiteType).to(beFalse())
  }
}
