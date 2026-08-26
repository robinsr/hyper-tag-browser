import XCTest

struct DetailScreen {
    let app: XCUIApplication

    var tagSearchField: XCUIElement  { app.searchFields["tag-search-field"] }
    var appliedTagsView: XCUIElement { app.otherElements["applied-tags-view"] }
}
