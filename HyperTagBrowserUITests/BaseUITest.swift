import XCTest

class BaseUITest: XCTestCase {
    var env: UITestEnvironment!

    override func setUpWithError() throws {
        continueAfterFailure = false
        env = try UITestEnvironment.setUp()
    }

    override func tearDownWithError() throws {
        env.tearDown()
    }
}
