import XCTest

struct BrowseScreen {
    let app: XCUIApplication

    var fileGrid: XCUIElement       { app.grids["photo-grid"] }
    var sidebar: XCUIElement        { app.scrollViews["browse-sidebar"] }
    var bookmarksList: XCUIElement  { app.otherElements["bookmarks-list"] }
}
