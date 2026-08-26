import XCTest

final class SavedQueryTests: BaseUITest {

    override func setUpWithError() throws {
        continueAfterFailure = false
        env = try UITestEnvironment.setUp(loadSavedQuery: UITestFixtures.savedQueryId)
    }

    func test_saved_query_populates_file_grid() {
        let screen = BrowseScreen(app: env.app)
        XCTAssertTrue(screen.fileGrid.waitForExistence(timeout: 10),
                      "File grid should be visible on launch")

        // Saved query filters for "red"-tagged files; only uitest-image-alpha should match
        let firstCell = screen.fileGrid.children(matching: .any).firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10),
                      "File grid should have at least one result from saved query")
    }
}
