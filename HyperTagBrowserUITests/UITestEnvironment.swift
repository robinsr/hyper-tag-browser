import Foundation
import XCTest

struct UITestEnvironment {
    let tempDir: URL
    let app: XCUIApplication

    static func setUp(
        liveIndex: Bool = false,
        loadSavedQuery: String? = nil
    ) throws -> UITestEnvironment {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HyperTagBrowserUITest-\(UUID().uuidString)")

        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true)

        let bundle = Bundle(for: BaseUITest.self)
        guard let resourcesURL = bundle.resourceURL else {
            throw UITestError.fixturesBundleNotFound
        }

        for filename in UITestFixtures.fixtureFileNames {
            let src = resourcesURL.appendingPathComponent(filename)
            let dst = tempDir.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: src.path) else {
                throw UITestError.fixtureFileMissing(filename)
            }
            try FileManager.default.copyItem(at: src, to: dst)
        }

        let app = XCUIApplication()
        var args = [
            "--UITestMode",
            "--LaunchFolderPath=\(tempDir.path)",
            "--OpenPanels=sidebar,bookmarks",
        ]
        if liveIndex { args.append("--LiveIndex") }
        if let queryId = loadSavedQuery { args.append("--LoadSavedQuery=\(queryId)") }

        app.launchArguments = args
        app.launch()

        return UITestEnvironment(tempDir: tempDir, app: app)
    }

    func tearDown() {
        app.terminate()
        try? FileManager.default.removeItem(at: tempDir)
    }
}
