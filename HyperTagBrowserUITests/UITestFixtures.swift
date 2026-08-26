import Foundation

enum UITestFixtures {
    static let savedQueryId = "uitest-saved-query-1"

    static let fixtureFileNames = [
        "uitest-image-alpha.jpg",
        "uitest-image-beta.jpg",
        "uitest-image-gamma.jpg",
    ]
}

enum UITestError: Error {
    case fixturesBundleNotFound
    case fixtureFileMissing(String)
}
