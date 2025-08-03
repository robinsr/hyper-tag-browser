// created on 5/9/25 by robinsr

import SwiftUI


struct TestData {
  static let fs = LocalFileService(monitoring: false)
  
  static let profile = ActiveUserProfile(suite: UserDefaults(suiteName: "com.robinsr.taggedfilebrowser.previews")!)
  
  
  // ======================
  // Test Data - FILE PATHS
  // ======================
  
  static let homeDir = UserLocation.home
  
  static let workspaceDir: URL = homeDir.appending(path: "workspace/xcode/TaggedFileBrowser/")
  static let dbFile: URL = workspaceDir.appending(path: "previewdb.sqlite")
  static let appDir: URL = workspaceDir.appending(path: "TaggedFileBrowser/App/")
  static let projectDir: URL = homeDir.appending(path: "workspace/projects/taggedfilebrowser/")
  static let testImageDir: URL = projectDir.appending(path: "testimages/")
  
  
  // ================
  // Test Data - URLs
  // ================
  
  static var testImageURLs: [URL] {
    fs.listURLs(at: testImageDir, types: .images)
  }
  
  static var testDirFiles: [URL] {
    fs.listURLs(at: testImageDir, types: .all)
  }
  
  
  // =========================
  // Test Data - CONTENT ITEMS
  // =========================
  
  static let testIndexRecords: [IndexRecord] = TestData.testImageURLs.compactMap {
    try? IndexRecord(fileURL: $0, contentId: .newID(using: .random, forURL: $0))
  }

  static var testContentItems: [IndexInfoRecord] {
    fs.listIndexedContents(of: testImageDir, mode: .immediate(.uncached), types: .images).compactMap { pointer, url in
      IndexInfoRecord.fromURL(url, pointer)
    }
  }
  
  
  // ========================
  // Test Data - TAGS/FILTERS
  // ========================
  
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
  
  
  // ==================
  // Test Data - IMAGES
  // ==================
  
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

    return imgURLs
      .filter { $0.fileSize <= maxSize } // Filter by size if specified
      .prefix(limit)
      .compactMap { NSImage(contentsOf: $0)?.asCGImage() }
      .compactMap { size == .full ? $0 : size.cgImage(for: $0) }
      .map { NSImage(cgImage: $0) }
  }
  
    // =====================
    // Test Data - BOOKMARKS
    // =====================
  
  static let testBookmarkContentItems: [ContentItem] = {
    fs.listIndexedContents(
      of: testImageDir,
      mode: .recursive(.uncached),
      types: .folders
    )
    .compactMap { pointer, url in
      IndexInfoRecord.fromURL(url, pointer)
    }
  }()
  
  
  static let testBookmarks: [BookmarkInfoRecord] = {
    testBookmarkContentItems.map { content in
      BookmarkInfoRecord(
        bookmark: BookmarkRecord(
          id: .randomIdentifier(10),
          contentId: content.id,
          created: Date.now.adding(.minute, value: Int.random(in: -1_000...10_000) * -1)
        ),
        content: content.index
      )
    }
  }()
  
  // ============================
  // Test Data - TEXT and STRINGS
  // ============================
  
  static var LOREM: String = {
    let lines = [
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor",
      "incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud",
      "exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute",
      "irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla",
      "pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia",
      "deserunt mollit anim id est laborum",
    ]
    
    return lines.joined(separator: " ")
  }()
  
  static var LOREM_WORDS: [String] = {
    LOREM.split(separator: " ").map(String.init)
  }()
  
  static var LOREM_SENTENCES: [String] = {
    LOREM.split(separator: ". ").map(String.init)
  }()
  
  static var LOREM_MATCH = ["in", "ad", "quis", "comm", "or", "ru", "is", "ex", " al"]
  static var LOREM_NO_MATCH: [[String]] = [ ["NOT", "FOUND", "IN", "LOREM", "IPSUM"], [] ]
  
  static func lorem(sentences count: Int = 3) -> String {
    Array(repeating: "", count: count)
      .map { _ in LOREM_SENTENCES.randomElement()! }
      .joined(separator: ". ")
  }
  
  static var testMessages: [AppMessage] {
    [
      .info(lorem(sentences: 7)),
      .ok(lorem(sentences: 7)),
      .warning(lorem(sentences: 7)),
      .error(lorem(sentences: 7)),
      .fatal(lorem(sentences: 7)),
    ]
  }
  
  enum RGBTestCases: String, CaseIterable {
    case red, green, blue
  }
}


let PreviewData = TestData()
