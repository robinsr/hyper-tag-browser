import XCTest

final class AppLaunchTests: BaseUITest {

    func test_app_launches_with_file_grid_and_sidebar_visible() {
        let screen = BrowseScreen(app: env.app)
        XCTAssertTrue(screen.fileGrid.waitForExistence(timeout: 5))
        XCTAssertTrue(screen.sidebar.waitForExistence(timeout: 5))
    }
}
