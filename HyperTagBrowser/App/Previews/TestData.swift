// created on 5/9/25 by robinsr

import SwiftUI
import System


@MainActor
struct TestData {
  
  static let fs = LocalFileService(monitoring: false)

  // MARK: - Test User Profile

  static let profile = ActiveUserProfile(
    suite: UserDefaults(suiteName: "com.robinsr.htb.previews")!)

  
  // MARK: - Test filepaths

  
  
  private static let project = Constants.appDisplayName
  private static let homedir = UserLocation.home.filepath
  private static let libdir = URL.libraryDirectory.filepath

  static let workdir = homedir.appending("workspace/xcode/HyperTagBrowser")
  static let source = workdir.appending("HyperTagBrowser/App")
  static let resourcesdir = homedir.appending("workspace/projects/taggedfilebrowser")
  static let dbFile = resourcesdir.appending("previewdb.sqlite")
  static let testImageDir = resourcesdir.appending("testimages")
  static let cloudImageDir = libdir.appending("Mobile Documents/com~apple~CloudDocs/Images/wallpapers")

  
  // MARK: - Test URLs

  static var testImageURLs = fs.listURLs(at: testImageDir.fileURL, types: .images)
  static var testImagePaths = testImageURLs.map { $0.filepath }
  static var testDirFiles = fs.listURLs(at: testImageDir.fileURL, types: .all)
  static var testDirFolders = fs.listURLs(at: testImageDir.fileURL, mode: .recursive(.uncached), types: .folders)
  
  static var cloudImageURLs = fs.listURLs(at: cloudImageDir.fileURL, types: .images)
  static var cloudDirFiles = fs.listURLs(at: cloudImageDir.fileURL, types: .all)

  // MARK: - Test ContentItems (IndexInfoRecord)

  static let testIndexRecords: [IndexRecord] = testImageURLs.compactMap {
    try? IndexRecord(fileURL: $0, contentId: .newID(using: .random, filepath: $0.filepath))
  }

  private static func buildContentItems(for path: FilePath, types: ContentTypeGroup = .all) -> [ContentItem] {
    fs.listIndexedContents(of: path.fileURL, mode: .recursive(.uncached), types: .folders).compactMap {
      IndexInfoRecord.fromURL($1, $0)
    }
  }

  static var testContentItems: [IndexInfoRecord] = buildContentItems(for: testImageDir, types: .images)
  static var cloudContentItems: [IndexInfoRecord] = buildContentItems(for: cloudImageDir, types: .images)
  static let testFolderItems: [ContentItem] = buildContentItems(for: testImageDir, types: .folders)
  static let cloudFolderItems: [ContentItem] = buildContentItems(for: cloudImageDir, types: .folders)

  
  // MARK: - Test Tags (FilteringTag)

  static let fruitTags: [FilteringTag] = [
    .tag("Apples"),
    .tag("Mighty Banana"),
    .tag("Spicy Pepper"),
    .tag("Hearty Durian"),
    .tag("Voltfruit"),
    .tag("Wildberry"),
    .tag("Hydromelon"),
    .tag("Palm Fruit"),
    .tag("Splashfruit"),
    .tag("Dazzlefruit"),
  ]

  static let vegetableTags: [FilteringTag] = [
    .tag("Swift Carrot"),
    .tag("Endura Carrot"),
    .tag("Stamella Shroom"),
    .tag("Rushroom"),
    .tag("Razorshroom"),
    .tag("Ironshroom"),
    .tag("Rushroom"),
    .tag("Silent Princess"),
    .tag("Courser Bee Honey"),
    .tag("Fleet-Lotus Seeds"),
  ]


  // MARK: - Test Images (NSImage)

  static var testImages: [NSImage] {
    testImageURLs.compactMap { NSImage(contentsOf: $0) }
  }

  /**
   * Same as `testImages` with additional filtering params for testing specific use cases.
   *
   * - Parameters:
   *   - limit: Max num of images to return. Defaults to `.max` (all images; test folder contents will vary)
   *   - maxSize: Filters out images larger than this size in bytes. Defaults to 1MB (1024 * 1024 bytes).
   *   - size: The target size to resize the images to. If `.full` or not specified, images will not be resized.
   *   - shuffled: Shuffle the order of images before returning them. Useful for seeing previews under a variety of user cases
   */
  static func testImages(
    limit: Int = .max,
    maxSize: UInt64 = 1024 * 1024,
    resizedTo size: ImageDisplay = .full,
    shuffled: Bool = false
  ) -> [NSImage] {
    let imgURLs = shuffled ? testImageURLs.shuffled() : testImageURLs

    return
      imgURLs
      .filter { $0.fileSize <= maxSize }          // Filter by size if specified
      .prefix(limit)
      .compactMap { NSImage(contentsOf: $0)?.asCGImage() }
      .compactMap { size == .full ? $0 : size.cgImage(for: $0) }
      .map { NSImage(cgImage: $0) }
  }

  
  // MARK: - Test Bookmarks (BookmarkInfoRecord)

  private static func buildBookmarks(for items: [ContentItem]) -> [BookmarkInfoRecord] {
    items.map { content in
      BookmarkInfoRecord(
        bookmark: BookmarkRecord(
          id: .randomIdentifier(10),
          contentId: content.id,
          created: Date.now.adding(.minute, value: Int.random(in: -1_000...10_000) * -1)
        ),
        content: content.index
      )
    }
  }

  static let testBookmarks: [BookmarkInfoRecord] = buildBookmarks(for: testFolderItems)
  static let cloudBookmarks: [BookmarkInfoRecord] = buildBookmarks(for: cloudFolderItems)

  
  // MARK: - Test Text and Strings

  static var testMessages: [AppMessage] {
    [
      .info(TestLorem.sentences(count: 7)),
      .ok(TestLorem.sentences(count: 7)),
      .warning(TestLorem.sentences(count: 7)),
      .error(TestLorem.sentences(count: 7)),
      .fatal(TestLorem.sentences(count: 7)),
    ]
  }

  enum RGBTestCases: String, CaseIterable {
    case red, green, blue
  }
}


struct TestLorem: Sendable {
  static var loremText: String {
    let lines = """
      Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
      quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
      consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
      cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
      proident, sunt in culpa qui officia deserunt mollit anim id est laborum
      """
    
    return lines.lines().joined(separator: " ")
  }
  
  static var loremWords: [String] {
    loremText.split(separator: " ").map(String.init)
  }
  
  static var uniqueWords: [String] {
    loremText.split(separator: " ").map(String.init).uniqued()
  }

  static var loremSentences: [String] {
    loremText.split(separator: ". ").map(String.init)
  }
  
  static func sampleWords(count: Int = 10) -> [String] {
    Array(repeating: "", count: count)
      .map { _ in loremWords.randomElement()! }
  }
  
  static func sentences(count: Int = 3) -> String {
    Array(repeating: "", count: count)
      .map { _ in loremSentences.randomElement()! }
      .joined(separator: ". ")
  }
}
