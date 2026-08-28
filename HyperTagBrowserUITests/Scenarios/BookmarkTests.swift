import XCTest

final class BookmarkTests: BaseUITest {

    func test_bookmark_created_appears_in_sidebar() {
        let browse = BrowseScreen(app: env.app)

        XCTAssertTrue(browse.fileGrid.waitForExistence(timeout: 10),
                      "File grid should be visible on launch")

        // Allow the app to fully settle
        Thread.sleep(forTimeInterval: 2.0)

        // Enumerate all static texts to find the bookmark header
        let allTexts = env.app.staticTexts.allElementsBoundByIndex.prefix(30)
        let textLabels = allTexts.map { "'\($0.label)'|\($0.identifier)" }.joined(separator: ", ")

        let sidebarExists = browse.sidebar.exists
        let bookmarksHeaderExists = env.app.staticTexts["Bookmarks"].exists
        let bookmarksListExists = browse.bookmarksList.exists

        // This assertion will always fail so we get the diagnostic output
        XCTAssertTrue(false,
                      "Diagnostic: sidebar=\(sidebarExists), bookmarksHeader=\(bookmarksHeaderExists), bookmarksList=\(bookmarksListExists). StaticTexts: [\(textLabels)]")
    }
}
