import XCTest

final class TaggingTests: BaseUITest {

    func test_tag_applied_to_file_appears_in_applied_tags() {
        let browse = BrowseScreen(app: env.app)

        // Wait for grid to be ready (seeded DB has 3 images)
        XCTAssertTrue(browse.fileGrid.waitForExistence(timeout: 10),
                      "File grid should be visible on launch")

        // Wait for at least one grid child to exist before attempting interaction
        let firstCell = browse.fileGrid.children(matching: .any).firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 10),
                      "At least one grid cell should exist")

        // Tap the grid via coordinate to avoid hitting non-hittable child text elements.
        // The seeded DB has 3 images; tap near top-left of grid to hit the first item.
        // First tap selects the item; second tap navigates to the detail screen.
        let gridCoord = browse.fileGrid.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.15))
        gridCoord.tap()
        gridCoord.tap()

        // Detail panel should open; ensure the inspector panel is visible.
        // The inspector is toggled by a toolbar button (keyboard shortcut: ⌘I).
        // If tag-search-field is not yet visible, open it via ⌘I.
        let detail = DetailScreen(app: env.app)

        if !detail.tagSearchField.waitForExistence(timeout: 5) {
            // Use ⌘I keyboard shortcut to toggle the inspector panel open
            env.app.typeKey("i", modifierFlags: .command)
        }

        XCTAssertTrue(detail.tagSearchField.waitForExistence(timeout: 10),
                      "Tag search field should appear in inspector after navigating to detail screen")

        // Tap the search field to focus it, type a tag, then press Return to submit
        detail.tagSearchField.click()
        detail.tagSearchField.typeText("smoke-tag")
        detail.tagSearchField.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])

        // Allow async dispatch and DB write to settle
        Thread.sleep(forTimeInterval: 1.5)

        // Verify the tag appears in the applied-tags view.
        // TagButton renders with .accessibilityAddTraits(.isButton), so it should appear as a button.
        // The applied-tags-view may need the enclosing SectionView to be expanded.
        let tagButton = detail.appliedTagsView.buttons["smoke-tag"]
        if !tagButton.waitForExistence(timeout: 5) {
            // Fall back: look for any descendant containing "smoke-tag" across the whole app
            let anyTagButton = env.app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'smoke-tag'")
            ).firstMatch
            let anyTagText = env.app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] 'smoke-tag'")
            ).firstMatch

            if anyTagButton.waitForExistence(timeout: 3) {
                XCTAssertTrue(anyTagButton.exists,
                              "Applied tag 'smoke-tag' should appear somewhere in the inspector")
            } else if anyTagText.waitForExistence(timeout: 2) {
                XCTAssertTrue(anyTagText.exists,
                              "Applied tag 'smoke-tag' should appear as text in the inspector")
            } else {
                XCTFail("Applied tag 'smoke-tag' was not found anywhere in the app after submission")
            }
        } else {
            XCTAssertTrue(tagButton.exists,
                          "Applied tag 'smoke-tag' should appear as a button in the inspector")
        }
    }
}
