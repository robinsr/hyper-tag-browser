import XCTest

// TODO: This test requires the app to automatically index the --LaunchFolderPath directory on
// startup when --LiveIndex is passed. Currently the app does not consume launchFolderPath for
// triggering live indexing — it only uses it to set the database path (UITestLaunchHandler.configure)
// and seed fixture data (UITestLaunchHandler.seed, which is skipped when liveIndex=true).
// Normal indexing is triggered via user action (AppViewModel.doIndexDirectory). Until the app
// gains a startup code path that detects --LiveIndex + --LaunchFolderPath and auto-indexes the
// specified folder, this test will time out waiting for the grid to populate.

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
