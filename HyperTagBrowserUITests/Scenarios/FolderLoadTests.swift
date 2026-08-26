import XCTest

final class FolderLoadTests: BaseUITest {

    override func setUpWithError() throws {
        continueAfterFailure = false
        env = try UITestEnvironment.setUp(liveIndex: true)
    }

    func test_folder_loads_files_via_live_indexing() {
        let screen = BrowseScreen(app: env.app)
        // Wait for at least one cell to appear (indexer is async)
        let firstCell = screen.fileGrid.children(matching: .any).firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 15),
                      "Expected file grid to populate within 15s after live indexing")
    }
}
