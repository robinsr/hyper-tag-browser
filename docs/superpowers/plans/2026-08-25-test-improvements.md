# Test Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add reliable, repeatable XCUITest smoke coverage of HyperTagBrowser's file-system-integrated behavior and systematic unit test coverage for the GRDB query and pure logic layers.

**Architecture:** XCUITests use a hermetic `UITestEnvironment` that creates a fresh temp directory, copies fixture files from the test bundle, and launches the app in UITest mode where it seeds its own SQLite database from `#if DEBUG` fixture definitions. Unit tests use the existing `TestSupportDB.setupDB()` infrastructure (Swift Testing + Nimble, in-memory GRDB).

**Tech Stack:** Swift Testing, Nimble, XCTest, GRDB, Factory DI, SwiftUI, macOS 15.0+

**Spec:** `docs/superpowers/specs/2026-08-25-test-improvements-design.md`

## Global Constraints

- macOS 15.0+ deployment target — do not use APIs introduced after macOS 15
- All unit tests: `import Testing` + `@Suite`/`@Test` + Nimble matchers — no Quick, no XCTest assertions
- All UITests: `XCTestCase` + Nimble matchers — no Quick
- Every new Swift file must be added to the correct Xcode target via Xcode's File Navigator after creation — Xcode will not pick up new files automatically
- Unit test target: `HyperTagBrowserTests`; UITest target: `HyperTagBrowserUITests`; App target: `HyperTagBrowser`
- Run all unit tests: `xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests`
- Run one test class: `xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests/<ClassName>`
- Run UITests: `xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserUITests`
- `swift-format` before every commit (config at `HyperTagBrowser/.swift-format`)
- Do not edit `versioning.xcconfig` manually

---

## Phase 0 — Prerequisites

### Task 0: Re-enable existing unit tests

This is a hard gate. No new tests are written until the existing suite is green.

**Files:**
- Modify: `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBTagsTest.swift`
- Modify: `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBIndexesTest.swift`
- Modify: `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBTagAssociationsTest.swift`
- Modify: `HyperTagBrowserTests/App/Services/Indexer/Requests/ListIndexInfoRequestTest.swift`
- Modify: `HyperTagBrowserTests/App/Components/Input/ValidatorTests.swift`
- Modify: `HyperTagBrowserTests/App/Data/FilteringTagTest.swift`
- Modify: `HyperTagBrowserTests/App/Services/Indexer/Records/Views/AppliedTagRecordTest.swift`

**Interfaces:**
- Produces: a green unit test suite

- [ ] **Step 1: Remove all `.disabled(...)` attributes**

In every file listed above, delete every occurrence of `.disabled("Disabled for project migration")` from `@Test` declarations. Example — change:

```swift
@Test(".createTagRecord(for:) - Creates a TagRecord for a FilteringTag", .disabled("Disabled for project migration"))
func test_create_tag_with_value() async throws {
```

to:

```swift
@Test(".createTagRecord(for:) - Creates a TagRecord for a FilteringTag")
func test_create_tag_with_value() async throws {
```

- [ ] **Step 2: Build the project**

```bash
xcodebuild build -scheme HyperTagBrowser -destination 'platform=macOS'
```

Expected: zero errors. Fix any that appear (likely caused by method renames during the TaggedFileBrowser → HyperTagBrowser migration).

- [ ] **Step 3: Run the full unit test suite**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests 2>&1 | tail -40
```

Expected: all tests pass. Fix any failures before proceeding.

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserTests/
git commit -m "Re-enable unit tests disabled during TaggedFileBrowser migration."
```

---

## Phase 1 — XCUITest Infrastructure

### Task 1: Commit UITest fixture files

**Files:**
- Create: `HyperTagBrowserUITests/TestFixtures/Files/uitest-image-alpha.jpg`
- Create: `HyperTagBrowserUITests/TestFixtures/Files/uitest-image-beta.jpg`
- Create: `HyperTagBrowserUITests/TestFixtures/Files/uitest-image-gamma.jpg`

**Interfaces:**
- Produces: three committed image files accessible as UITest bundle resources; their filenames are referenced by `UITestFixtureSeeder` in Task 3

- [ ] **Step 1: Copy three fixture files**

Copy any three JPEGs from `/Users/ryan/workspace/projects/taggedfilebrowser/testimages/` into `HyperTagBrowserUITests/TestFixtures/Files/`, renaming them to:
- `uitest-image-alpha.jpg`
- `uitest-image-beta.jpg`
- `uitest-image-gamma.jpg`

```bash
mkdir -p HyperTagBrowserUITests/TestFixtures/Files
cp "/Users/ryan/workspace/projects/taggedfilebrowser/testimages/[Alan Alves] C0 O3Aop7Ro.jpg" \
   HyperTagBrowserUITests/TestFixtures/Files/uitest-image-alpha.jpg
cp "/Users/ryan/workspace/projects/taggedfilebrowser/testimages/[Annie Spratt] Fsgznsmyg90.jpg" \
   HyperTagBrowserUITests/TestFixtures/Files/uitest-image-beta.jpg
cp "/Users/ryan/workspace/projects/taggedfilebrowser/testimages/[Anshu A] Dfoscjcmveu.jpg" \
   HyperTagBrowserUITests/TestFixtures/Files/uitest-image-gamma.jpg
```

- [ ] **Step 2: Add files to the UITest target in Xcode**

In Xcode's File Navigator, right-click `HyperTagBrowserUITests/TestFixtures/Files/`, choose "Add Files to HyperTagBrowser…", select the three files, and ensure "HyperTagBrowserUITests" is checked as the target. Verify they appear in the target's "Copy Bundle Resources" build phase.

- [ ] **Step 3: Commit**

```bash
git add HyperTagBrowserUITests/TestFixtures/
git commit -m "Add UITest fixture image files."
```

---

### Task 2: Add UITest launch argument keys to RunFlags

**Files:**
- Modify: `HyperTagBrowser/App/Data/Runtime/RunFlags.swift`

**Interfaces:**
- Produces: `RunFlags.uiTestMode: Bool`, `RunFlags.liveIndex: Bool`, `RunFlags.launchFolderPath: String?`, `RunFlags.loadSavedQuery: String?` — consumed by `UITestLaunchHandler` in Task 3

- [ ] **Step 1: Add keys to `CodingKeys` and computed properties**

In `RunFlags.swift`, add four new cases to `CodingKeys` and four new computed properties:

```swift
enum CodingKeys: String, CodingKey, CaseIterable {
    case profileId = "--profile"
    case profileName = "--profile-name"
    case emitMetrics = "--emit-metrics"
    // NEW:
    case uiTestMode = "--UITestMode"
    case liveIndex = "--LiveIndex"
    case launchFolderPath = "--LaunchFolderPath"
    case loadSavedQuery = "--LoadSavedQuery"
}

// Add below the existing computed properties:
var uiTestMode: Bool {
    hasRuntimeArgument(CodingKeys.uiTestMode.rawValue)
}

var liveIndex: Bool {
    hasRuntimeArgument(CodingKeys.liveIndex.rawValue)
}

var launchFolderPath: String? {
    getRuntimeValue(forKey: CodingKeys.launchFolderPath.rawValue)
}

var loadSavedQuery: String? {
    getRuntimeValue(forKey: CodingKeys.loadSavedQuery.rawValue)
}
```

- [ ] **Step 2: Build to confirm no errors**

```bash
xcodebuild build -scheme HyperTagBrowser -destination 'platform=macOS' 2>&1 | grep -E "error:|Build succeeded"
```

- [ ] **Step 3: Commit**

```bash
git add HyperTagBrowser/App/Data/Runtime/RunFlags.swift
git commit -m "Add UITest launch argument keys to RunFlags."
```

---

### Task 3: Create UITestLaunchHandler and UITestFixtureSeeder (app, DEBUG only)

The app reads `--UITestMode` and, if present, redirects its database to a temp path and seeds it with known fixture records. This keeps all fixture logic in one `#if DEBUG` file and leaves zero UITest-specific code in production builds.

**Files:**
- Create: `HyperTagBrowser/App/UITestSupport/UITestLaunchHandler.swift`
- Modify: `HyperTagBrowser/App/App.swift`

**Interfaces:**
- Consumes: `RunFlags` (Task 2), `IndexerContainer.shared.databasePath`, `GRDBIndexService.configure()`
- Produces: app launched in UITest mode uses a hermetic SQLite database seeded with known fixture records; `UITestFixtureSeeder.savedQueryId` constant is used by UITest scenarios

- [ ] **Step 1: Create `UITestLaunchHandler.swift`**

Create `HyperTagBrowser/App/UITestSupport/UITestLaunchHandler.swift` and add it to the **HyperTagBrowser** app target in Xcode.

```swift
#if DEBUG
import Foundation
import GRDB
import System
import UniformTypeIdentifiers

struct UITestFixtureSeeder {
    static let savedQueryId = "uitest-saved-query-1"

    static func indexRecords(in tempDir: URL) -> [IndexRecord] {
        let dir = FilePath(tempDir.path)
        let now = Date.now

        return [
            makeIndexRecord(
                id: "content:uitest-alpha",
                name: "uitest-image-alpha.jpg",
                location: dir,
                type: UTType.jpeg,
                date: now),
            makeIndexRecord(
                id: "content:uitest-beta",
                name: "uitest-image-beta.jpg",
                location: dir,
                type: UTType.jpeg,
                date: now),
            makeIndexRecord(
                id: "content:uitest-gamma",
                name: "uitest-image-gamma.jpg",
                location: dir,
                type: UTType.jpeg,
                date: now),
            makeIndexRecord(
                id: "content:uitest-folder",
                name: tempDir.lastPathComponent,
                location: FilePath(tempDir.deletingLastPathComponent().path),
                type: UTType.folder,
                date: now,
                visibility: .normal),
        ]
    }

    static var tagRecords: [TagRecord] {
        [
            TagRecord(id: "tag:uitest-red",  tagValue: "red",  tagType: .tag),
            TagRecord(id: "tag:uitest-blue", tagValue: "blue", tagType: .tag),
        ]
    }

    static var indexTagRecords: [IndexTagRecord] {
        [
            IndexTagRecord(contentId: ContentId(existing: "content:uitest-alpha"),
                           tagId: "tag:uitest-red"),
            IndexTagRecord(contentId: ContentId(existing: "content:uitest-beta"),
                           tagId: "tag:uitest-blue"),
        ]
    }

    static var savedQueryRecords: [SavedQueryRecord] {
        var filters = BrowseFilters()
        filters.tagsMatching = FilteringTagMultiParam(
            [FilteringTag.tag("red").asInclusive], operator: .or)
        return [
            SavedQueryRecord(id: savedQueryId, name: "UITest: Red Images", query: filters),
        ]
    }

    private static func makeIndexRecord(
        id: String,
        name: String,
        location: FilePath,
        type: UTType,
        date: Date,
        visibility: ContentItemVisibility = .normal
    ) -> IndexRecord {
        IndexRecord(
            id: ContentId(existing: id),
            name: name,
            location: location,
            type: type.identifier,
            size: 1024,
            created: date,
            modified: date,
            visibility: visibility)
    }
}


struct UITestLaunchHandler {

    static func configure(flags: RunFlags) {
        guard flags.uiTestMode, let folderPath = flags.launchFolderPath else { return }

        let tempDir = URL(fileURLWithPath: folderPath)
        let dbPath = FilePath(tempDir.appendingPathComponent(".hypertag-uitest.sqlite").path)

        IndexerContainer.shared.databasePath.register { dbPath }
    }

    static func seed(service: GRDBIndexService, flags: RunFlags) throws {
        guard flags.uiTestMode, !flags.liveIndex,
              let folderPath = flags.launchFolderPath else { return }

        let tempDir = URL(fileURLWithPath: folderPath)
        let dbPath = FilePath(tempDir.appendingPathComponent(".hypertag-uitest.sqlite").path)

        let db = try DatabaseQueue(path: dbPath.string, configuration: GRDBIndexService.configure())

        try db.write { conn in
            for record in UITestFixtureSeeder.indexRecords(in: tempDir) {
                try record.insert(conn)
            }
            for record in UITestFixtureSeeder.tagRecords {
                try record.insert(conn)
            }
            for record in UITestFixtureSeeder.indexTagRecords {
                try record.insert(conn)
            }
            for record in UITestFixtureSeeder.savedQueryRecords {
                try record.insert(conn)
            }
        }
    }
}
#endif
```

> **Note:** `IndexRecord`, `TagRecord`, `IndexTagRecord`, `SavedQueryRecord`, `BrowseFilters`, `FilteringTagMultiParam`, `FilteringTag`, `ContentItemVisibility`, `ContentId`, and `GRDBIndexService` are all production types from `@testable import HyperTagBrowser` — no import needed since this file is part of the app target.

- [ ] **Step 2: Modify `App.swift` `main()` to call the handler**

In `HyperTagBrowser/App/App.swift`, replace the existing `main()` body:

```swift
static func main() {
    measurementEnabled = false

    EnvContainer.shared.reset(options: .context)

    if AppStage.isUnitTest {
        TestApp.main()
        return
    }

    let runFlags = RunFlags()

    #if DEBUG
    UITestLaunchHandler.configure(flags: runFlags)
    #endif

    let indexer = IndexerContainer.shared.indexService()

    do {
        try indexer.runMigrations()

        #if DEBUG
        try UITestLaunchHandler.seed(service: indexer, flags: runFlags)
        #endif

        TaggedFileBrowserApp.main()
    } catch {
        fatalError("Failed to start app: \(error.legibleDescription)")
    }
}
```

- [ ] **Step 3: Build**

```bash
xcodebuild build -scheme HyperTagBrowser -destination 'platform=macOS' 2>&1 | grep -E "error:|Build succeeded"
```

Fix any errors. Common issues: `IndexRecord` initializer parameters — verify against `HyperTagBrowser/App/Services/Indexer/Records/Content/IndexRecord.swift` and adjust the `makeIndexRecord` helper to match the actual memberwise initializer.

- [ ] **Step 4: Run unit tests to confirm nothing regressed**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add HyperTagBrowser/App/UITestSupport/UITestLaunchHandler.swift \
        HyperTagBrowser/App/App.swift
git commit -m "Add UITestLaunchHandler and UITestFixtureSeeder for hermetic XCUITest environment."
```

---

### Task 4: Create UITestEnvironment helper

**Files:**
- Create: `HyperTagBrowserUITests/UITestEnvironment.swift`
- Create: `HyperTagBrowserUITests/UITestFixtures.swift`

**Interfaces:**
- Consumes: `UITestFixtureSeeder.savedQueryId` indirectly (referenced as a string constant mirrored here)
- Produces: `UITestEnvironment` struct with `setUp(liveIndex:loadSavedQuery:)` and `tearDown()`; `UITestFixtures.savedQueryId` constant; `UITestError` enum

- [ ] **Step 1: Create `UITestFixtures.swift`**

Create `HyperTagBrowserUITests/UITestFixtures.swift` and add to the **HyperTagBrowserUITests** target.

```swift
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
```

- [ ] **Step 2: Create `UITestEnvironment.swift`**

Create `HyperTagBrowserUITests/UITestEnvironment.swift` and add to the **HyperTagBrowserUITests** target.

```swift
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
```

- [ ] **Step 3: Create `BaseUITest.swift`**

Create `HyperTagBrowserUITests/BaseUITest.swift` and add to the **HyperTagBrowserUITests** target.

```swift
import XCTest
import Nimble

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
```

- [ ] **Step 4: Build UITest target**

```bash
xcodebuild build -scheme HyperTagBrowser -destination 'platform=macOS' 2>&1 | grep -E "error:|Build succeeded"
```

- [ ] **Step 5: Commit**

```bash
git add HyperTagBrowserUITests/UITestEnvironment.swift \
        HyperTagBrowserUITests/UITestFixtures.swift \
        HyperTagBrowserUITests/BaseUITest.swift
git commit -m "Add UITestEnvironment, UITestFixtures, and BaseUITest infrastructure."
```

---

### Task 5: Create screen objects

**Files:**
- Create: `HyperTagBrowserUITests/Screens/BrowseScreen.swift`
- Create: `HyperTagBrowserUITests/Screens/DetailScreen.swift`
- Delete: `HyperTagBrowserUITests/Screens/Browse/BrowseScreenUITest.swift` (old Quick placeholder)
- Delete: `HyperTagBrowserUITests/App/Screens/Browse/BrowseScreenUITest.swift` (empty file)

**Interfaces:**
- Consumes: `UITestEnvironment.app` (XCUIApplication)
- Produces: `BrowseScreen(app:)` and `DetailScreen(app:)` — used by all five scenario tasks

- [ ] **Step 1: Delete the old Quick-based file**

In Xcode, delete `HyperTagBrowserUITests/Screens/Browse/BrowseScreenUITest.swift` and `HyperTagBrowserUITests/App/Screens/Browse/BrowseScreenUITest.swift` — choose "Move to Trash" when Xcode prompts.

- [ ] **Step 2: Create `Screens/BrowseScreen.swift`**

Create `HyperTagBrowserUITests/Screens/BrowseScreen.swift` and add to **HyperTagBrowserUITests**.

```swift
import XCTest

struct BrowseScreen {
    let app: XCUIApplication

    var fileGrid: XCUIElement       { app.grids["photo-grid"] }
    var sidebar: XCUIElement        { app.scrollViews["browse-sidebar"] }
    var bookmarksList: XCUIElement  { app.otherElements["bookmarks-list"] }
}
```

- [ ] **Step 3: Create `Screens/DetailScreen.swift`**

Create `HyperTagBrowserUITests/Screens/DetailScreen.swift` and add to **HyperTagBrowserUITests**.

```swift
import XCTest

struct DetailScreen {
    let app: XCUIApplication

    var tagSearchField: XCUIElement  { app.searchFields["tag-search-field"] }
    var appliedTagsView: XCUIElement { app.otherElements["applied-tags-view"] }
}
```

- [ ] **Step 4: Build**

```bash
xcodebuild build -scheme HyperTagBrowser -destination 'platform=macOS' 2>&1 | grep -E "error:|Build succeeded"
```

- [ ] **Step 5: Commit**

```bash
git add HyperTagBrowserUITests/Screens/
git commit -m "Add BrowseScreen and DetailScreen objects; remove Quick placeholder."
```

---

### Task 6: Add accessibility identifiers to views

These are the only identifiers needed — add exactly these five, nothing more.

**Files:**
- Modify: `HyperTagBrowser/App/Screens/Browse/ContentGrid/PhotoGridView.swift:177`
- Modify: `HyperTagBrowser/App/Screens/Browse/BrowseScreen.swift:117`
- Modify: `HyperTagBrowser/App/Screens/Detail/Inspector/AddTagView.swift:79`
- Modify: `HyperTagBrowser/App/Screens/Detail/Inspector/ImageInspector.swift:61`
- Modify: `HyperTagBrowser/App/Screens/Sidebar/Bookmarks/Bookmarks_List.swift:31`

**Interfaces:**
- Produces: five accessibility identifiers that screen objects in Task 5 query by name

- [ ] **Step 1: `PhotoGridView.swift` — tag the `LazyVGrid`**

In `var LazyGridContent: some View`, add `.accessibilityIdentifier("photo-grid")` to the `LazyVGrid`:

```swift
var LazyGridContent: some View {
    LazyVGrid(columns: adaptiveCols, alignment: .center, spacing: gridRowSpacing) {
        ForEach(items.indexed, id: \.1.id) { index, item in
            PhotoGridItem(item: item, index: index)
                .background(GridItemGeometryPreferenceViewSetter(idx: index))
                .id(item.id.value)
        }
    }
    .accessibilityIdentifier("photo-grid")   // ADD THIS
}
```

- [ ] **Step 2: `BrowseScreen.swift` — tag the sidebar `ScrollView`**

In `var SideBarContent: some View`, add `.accessibilityIdentifier("browse-sidebar")` after `.scrollIndicators(.never)`:

```swift
var SideBarContent: some View {
    ScrollView {
        VStack(spacing: 8) {
            BookmarksList(isPresented: .bindToPanel(appVM, .bookmarks))
            Divider()
            WorkQueueSidebarMenu()
            Divider()
            ManageTagsView(isPresented: .bindToPanel(appVM, .tagmanager))
        }
        .scenePadding()
    }
    .scrollIndicators(.never)
    .accessibilityIdentifier("browse-sidebar")   // ADD THIS
}
```

- [ ] **Step 3: `AddTagView.swift` — tag the search field**

In `var TextInputAndKeyResponder: some View`, add `.accessibilityIdentifier("tag-search-field")` to the `SearchField`:

```swift
var TextInputAndKeyResponder: some View {
    SearchField(value: $newTagText.rawValue, placeholder: "Search Tags")
        .accessibilityIdentifier("tag-search-field")   // ADD THIS
        .isTyping($isFocused)
        // ... rest unchanged
}
```

- [ ] **Step 4: `ImageInspector.swift` — tag the applied-tags section**

In `DetailScreenInspectorContent(_:)`, add `.accessibilityIdentifier("applied-tags-view")` to the "Applied Tags" `SectionView`:

```swift
SectionView("Applied Tags", isPresented: $panelState.contains(.currentTags)) {
    CurrentTagsView(
        contentItem: .constant(content),
        domains: .constant([.descriptive])
    )
    CurrentTagsView(
        contentItem: .constant(content),
        domains: .constant([.queue])
    )
}
.accessibilityIdentifier("applied-tags-view")   // ADD THIS
```

- [ ] **Step 5: `Bookmarks_List.swift` — tag the list VStack**

In `var ListItems: some View`, add `.accessibilityIdentifier("bookmarks-list")` to the `VStack`:

```swift
var ListItems: some View {
    VStack(alignment: .leading, spacing: 2) {
        ForEach(indexedBookmarks, id: \.bookmark.id) { index, bookmark in
            BookmarksListItem(index: index, bookmark: bookmark)
                .id(bookmark.id)
        }
    }
    .accessibilityIdentifier("bookmarks-list")   // ADD THIS
}
```

- [ ] **Step 6: Build**

```bash
xcodebuild build -scheme HyperTagBrowser -destination 'platform=macOS' 2>&1 | grep -E "error:|Build succeeded"
```

- [ ] **Step 7: Commit**

```bash
git add HyperTagBrowser/App/Screens/Browse/ContentGrid/PhotoGridView.swift \
        HyperTagBrowser/App/Screens/Browse/BrowseScreen.swift \
        HyperTagBrowser/App/Screens/Detail/Inspector/AddTagView.swift \
        HyperTagBrowser/App/Screens/Detail/Inspector/ImageInspector.swift \
        HyperTagBrowser/App/Screens/Sidebar/Bookmarks/Bookmarks_List.swift
git commit -m "Add accessibility identifiers for XCUITest smoke scenarios."
```

---

## Phase 2 — XCUITest Scenarios

### Task 7: Scenario 1 — App launches cleanly

**Files:**
- Create: `HyperTagBrowserUITests/Scenarios/AppLaunchTests.swift`
- Modify: `HyperTagBrowserUITests/HyperTagBrowserUITests.swift` (remove boilerplate)

**Interfaces:**
- Consumes: `BaseUITest`, `BrowseScreen`

- [ ] **Step 1: Clear `HyperTagBrowserUITests.swift` boilerplate**

Replace the content of `HyperTagBrowserUITests/HyperTagBrowserUITests.swift` with a minimal placeholder:

```swift
// XCUITest scenarios are in HyperTagBrowserUITests/Scenarios/
```

- [ ] **Step 2: Create `AppLaunchTests.swift`**

Create `HyperTagBrowserUITests/Scenarios/AppLaunchTests.swift` and add to **HyperTagBrowserUITests**.

```swift
import XCTest
import Nimble

final class AppLaunchTests: BaseUITest {

    func test_app_launches_with_file_grid_and_sidebar_visible() {
        let screen = BrowseScreen(app: env.app)
        expect(screen.fileGrid.exists).to(beTrue())
        expect(screen.sidebar.exists).to(beTrue())
    }
}
```

- [ ] **Step 3: Run Scenario 1**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserUITests/AppLaunchTests 2>&1 | tail -20
```

Expected: PASS. If the grid or sidebar isn't found, verify the accessibility identifiers from Task 6 are on the correct elements and that the app actually launches (check for crashes in the output).

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserUITests/Scenarios/AppLaunchTests.swift \
        HyperTagBrowserUITests/HyperTagBrowserUITests.swift
git commit -m "Add Scenario 1: app launches cleanly XCUITest."
```

---

### Task 8: Scenario 2 — Folder loads via live indexing

**Files:**
- Create: `HyperTagBrowserUITests/Scenarios/FolderLoadTests.swift`

**Interfaces:**
- Consumes: `BaseUITest`, `BrowseScreen`, `UITestEnvironment.setUp(liveIndex: true)`

- [ ] **Step 1: Create `FolderLoadTests.swift`**

Create `HyperTagBrowserUITests/Scenarios/FolderLoadTests.swift` and add to **HyperTagBrowserUITests**.

```swift
import XCTest
import Nimble

final class FolderLoadTests: BaseUITest {

    override func setUpWithError() throws {
        continueAfterFailure = false
        env = try UITestEnvironment.setUp(liveIndex: true)
    }

    func test_folder_loads_files_via_live_indexing() {
        let screen = BrowseScreen(app: env.app)
        expect(screen.fileGrid.cells.count).toEventually(beGreaterThan(0), timeout: .seconds(15))
    }
}
```

> `toEventually` is used here because live indexing is asynchronous — the grid populates after the indexer finishes. The 15-second timeout is generous; indexing 3 files should take under a second.

- [ ] **Step 2: Run Scenario 2**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserUITests/FolderLoadTests 2>&1 | tail -20
```

Expected: PASS. If the grid never populates, check that `--LiveIndex` actually skips seeding and that the indexer runs when a folder path is set via `--LaunchFolderPath`.

- [ ] **Step 3: Commit**

```bash
git add HyperTagBrowserUITests/Scenarios/FolderLoadTests.swift
git commit -m "Add Scenario 2: folder loads via live indexing XCUITest."
```

---

### Task 9: Scenario 3 — Tag applied to a file

**Files:**
- Create: `HyperTagBrowserUITests/Scenarios/TaggingTests.swift`

**Interfaces:**
- Consumes: `BaseUITest`, `BrowseScreen`, `DetailScreen`

- [ ] **Step 1: Create `TaggingTests.swift`**

Create `HyperTagBrowserUITests/Scenarios/TaggingTests.swift` and add to **HyperTagBrowserUITests**.

```swift
import XCTest
import Nimble

final class TaggingTests: BaseUITest {

    func test_tag_applied_to_file_appears_in_applied_tags() {
        let browse = BrowseScreen(app: env.app)
        browse.fileGrid.cells.firstMatch.tap()

        let detail = DetailScreen(app: env.app)
        expect(detail.tagSearchField.exists).toEventually(beTrue(), timeout: .seconds(5))

        detail.tagSearchField.typeText("smoke-tag\n")

        expect(detail.appliedTagsView.buttons["smoke-tag"].exists)
            .toEventually(beTrue(), timeout: .seconds(5))
    }
}
```

- [ ] **Step 2: Run Scenario 3**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserUITests/TaggingTests 2>&1 | tail -20
```

Expected: PASS. If `tagSearchField` is not found, the DetailScreen inspector panel may not be opening on tap — check whether a single tap selects a file or opens the detail view, and adjust the interaction (may need a double-tap or a toolbar button tap to open the inspector).

- [ ] **Step 3: Commit**

```bash
git add HyperTagBrowserUITests/Scenarios/TaggingTests.swift
git commit -m "Add Scenario 3: tag applied to file XCUITest."
```

---

### Task 10: Scenario 4 — Saved query loads

**Files:**
- Create: `HyperTagBrowserUITests/Scenarios/SavedQueryTests.swift`

**Interfaces:**
- Consumes: `BaseUITest`, `BrowseScreen`, `UITestFixtures.savedQueryId`, `UITestEnvironment.setUp(loadSavedQuery:)`

- [ ] **Step 1: Create `SavedQueryTests.swift`**

Create `HyperTagBrowserUITests/Scenarios/SavedQueryTests.swift` and add to **HyperTagBrowserUITests**.

```swift
import XCTest
import Nimble

final class SavedQueryTests: BaseUITest {

    override func setUpWithError() throws {
        continueAfterFailure = false
        env = try UITestEnvironment.setUp(loadSavedQuery: UITestFixtures.savedQueryId)
    }

    func test_saved_query_populates_file_grid() {
        let screen = BrowseScreen(app: env.app)
        expect(screen.fileGrid.cells.count).toEventually(beGreaterThan(0), timeout: .seconds(10))
    }
}
```

> The saved query filters for files tagged "red". The seeder inserts one such record (`uitest-image-alpha`). If zero cells appear, verify that `--LoadSavedQuery=<id>` is wired up in the app — the app should apply this query on launch (this may require additional app-side handling: read the `loadSavedQuery` flag in `UITestLaunchHandler.configure` and dispatch `.loadSavedQuery(id)` before the UI is shown).

- [ ] **Step 2: Run Scenario 4**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserUITests/SavedQueryTests 2>&1 | tail -20
```

- [ ] **Step 3: Commit**

```bash
git add HyperTagBrowserUITests/Scenarios/SavedQueryTests.swift
git commit -m "Add Scenario 4: saved query loads XCUITest."
```

---

### Task 11: Scenario 5 — Bookmark created

**Files:**
- Create: `HyperTagBrowserUITests/Scenarios/BookmarkTests.swift`

**Interfaces:**
- Consumes: `BaseUITest`, `BrowseScreen`

- [ ] **Step 1: Create `BookmarkTests.swift`**

Create `HyperTagBrowserUITests/Scenarios/BookmarkTests.swift` and add to **HyperTagBrowserUITests**.

```swift
import XCTest
import Nimble

final class BookmarkTests: BaseUITest {

    func test_bookmark_created_appears_in_sidebar() {
        let browse = BrowseScreen(app: env.app)
        browse.fileGrid.cells.firstMatch.rightClick()
        env.app.menuItems.matching(NSPredicate(format: "label CONTAINS 'Bookmark'")).firstMatch.tap()

        expect(browse.bookmarksList.cells.count)
            .toEventually(beGreaterThan(0), timeout: .seconds(5))
    }
}
```

> The context menu label may differ from "Add Bookmark" — the `NSPredicate` with `CONTAINS 'Bookmark'` is intentionally flexible. If the bookmarksList still shows zero cells after the action, run the app manually and right-click a file to find the exact menu item label, then update the predicate.

- [ ] **Step 2: Run Scenario 5**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserUITests/BookmarkTests 2>&1 | tail -20
```

- [ ] **Step 3: Run the full UITest suite**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserUITests 2>&1 | tail -30
```

Expected: all 5 scenarios pass.

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserUITests/Scenarios/BookmarkTests.swift
git commit -m "Add Scenario 5: bookmark created XCUITest. All 5 smoke scenarios passing."
```

---

## Phase 3 — Unit Tests: Tier 1 GRDB Services

### Task 12: GRDBBookmarks unit tests

**Files:**
- Modify: `HyperTagBrowser/App/Services/Indexer/Service/GRDBBookmarks.swift` (reference — do not modify)
- Create: `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBBookmarksTest.swift`

**Interfaces:**
- Consumes: `TestSupportDB.setupDB()`, `GRDBIndexService` (BookmarkAccess), `IndexRecordFixture.Cases`

- [ ] **Step 1: Read the source file**

Read `HyperTagBrowser/App/Services/Indexer/Service/GRDBBookmarks.swift` in full. The public API is:
- `bookmarkExists(to:) throws -> Bool`
- `getBookmark(for:) throws -> BookmarkInfoRecord?`
- `getBookmark(withId:) throws -> BookmarkInfoRecord?`
- `findBookmark(withPath:) throws -> BookmarkInfoRecord?`
- `createBookmark(to:) throws -> BookmarkInfoRecord`
- `deleteBookmark(withId:) throws -> BookmarkInfoRecord?`
- `deleteBookmarks(to:) throws -> [BookmarkRecord]`

- [ ] **Step 2: Create `GRDBBookmarksTest.swift`**

Create `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBBookmarksTest.swift` and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("GRDBBookmarks", .serialized, .tags(.indexer))
struct GRDBBookmarksTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("bookmarkExists returns false when no bookmark exists")
    func test_bookmark_exists_false() async throws {
        let contentId = IndexRecordFixture.Cases.bakery.id
        await expect { try await self.service.bookmarkExists(to: contentId) }.to(beFalse())
    }

    @Test("createBookmark persists a bookmark and returns BookmarkInfoRecord")
    func test_create_bookmark() async throws {
        let contentId = IndexRecordFixture.Cases.bakery.id
        let result = try await service.createBookmark(to: contentId)
        expect(result.id).notTo(beEmpty())
        expect(result.contentId).to(equal(contentId))
    }

    @Test("bookmarkExists returns true after createBookmark")
    func test_bookmark_exists_true_after_create() async throws {
        let contentId = IndexRecordFixture.Cases.bbq.id
        let _ = try await service.createBookmark(to: contentId)
        await expect { try await self.service.bookmarkExists(to: contentId) }.to(beTrue())
    }

    @Test("createBookmark is idempotent — second call returns existing record")
    func test_create_bookmark_idempotent() async throws {
        let contentId = IndexRecordFixture.Cases.diner.id
        let first = try await service.createBookmark(to: contentId)
        let second = try await service.createBookmark(to: contentId)
        expect(first.id).to(equal(second.id))
    }

    @Test("getBookmark(for:) returns nil when no bookmark exists")
    func test_get_bookmark_returns_nil() async throws {
        let contentId = IndexRecordFixture.Cases.coffeeshop.id
        await expect { try await self.service.getBookmark(for: contentId) }.to(beNil())
    }

    @Test("getBookmark(for:) returns record after createBookmark")
    func test_get_bookmark_after_create() async throws {
        let contentId = IndexRecordFixture.Cases.bakery.id
        let created = try await service.createBookmark(to: contentId)
        let fetched = try await service.getBookmark(for: contentId)
        expect(fetched?.id).to(equal(created.id))
    }

    @Test("deleteBookmark removes the record")
    func test_delete_bookmark() async throws {
        let contentId = IndexRecordFixture.Cases.bbq.id
        let created = try await service.createBookmark(to: contentId)
        let _ = try await service.deleteBookmark(withId: created.id)
        await expect { try await self.service.bookmarkExists(to: contentId) }.to(beFalse())
    }

    @Test("deleteBookmarks(to:) removes all bookmarks for a contentId")
    func test_delete_bookmarks_for_content() async throws {
        let contentId = IndexRecordFixture.Cases.diner.id
        let _ = try await service.createBookmark(to: contentId)
        let deleted = try await service.deleteBookmarks(to: contentId)
        expect(deleted).notTo(beEmpty())
        await expect { try await self.service.bookmarkExists(to: contentId) }.to(beFalse())
    }
}
```

- [ ] **Step 3: Run the tests**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/GRDBBookmarksTest 2>&1 | tail -20
```

Expected: all tests pass. Fix any failures before proceeding.

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserTests/App/Services/Indexer/Service/GRDBBookmarksTest.swift
git commit -m "Add GRDBBookmarks unit tests."
```

---

### Task 13: GRDBSaves unit tests

**Files:**
- Modify: `HyperTagBrowser/App/Services/Indexer/Service/GRDBSaves.swift` (reference — do not modify)
- Create: `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBSavesTest.swift`

**Interfaces:**
- Consumes: `TestSupportDB.setupDB()`, `GRDBIndexService` (SavedQueryAccess), `BrowseFilters`

- [ ] **Step 1: Read the source file**

Read `HyperTagBrowser/App/Services/Indexer/Service/GRDBSaves.swift`. Public API:
- `savedQueryExists(withId:) throws -> Bool`
- `getSavedQuery(withId:) throws -> SavedQueryRecord?`
- `listSavedQueries() throws -> [SavedQueryRecord]`
- `createSavedQuery(named:using:) throws -> SavedQueryRecord`
- `updateSavedQuery(withId:using:) throws -> SavedQueryRecord`
- `renameSavedQuery(withId:to:) throws -> SavedQueryRecord`
- `deleteSavedQuery(withId:) throws -> Bool`

- [ ] **Step 2: Create `GRDBSavesTest.swift`**

Create `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBSavesTest.swift` and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("GRDBSaves", .serialized, .tags(.indexer))
struct GRDBSavesTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("listSavedQueries returns empty when none exist")
    func test_list_empty() async throws {
        await expect { try await self.service.listSavedQueries() }.to(beEmpty())
    }

    @Test("createSavedQuery persists and returns a SavedQueryRecord")
    func test_create_saved_query() async throws {
        let result = try await service.createSavedQuery(named: "My Query", using: BrowseFilters())
        expect(result.name).to(equal("My Query"))
        expect(result.id).notTo(beEmpty())
    }

    @Test("savedQueryExists returns true after create")
    func test_saved_query_exists_after_create() async throws {
        let created = try await service.createSavedQuery(named: "Exists Test", using: BrowseFilters())
        await expect { try await self.service.savedQueryExists(withId: created.id) }.to(beTrue())
    }

    @Test("getSavedQuery returns nil for unknown id")
    func test_get_saved_query_nil() async throws {
        await expect { try await self.service.getSavedQuery(withId: "nonexistent") }.to(beNil())
    }

    @Test("listSavedQueries returns all created records")
    func test_list_returns_all() async throws {
        let _ = try await service.createSavedQuery(named: "Alpha", using: BrowseFilters())
        let _ = try await service.createSavedQuery(named: "Beta", using: BrowseFilters())
        await expect { try await self.service.listSavedQueries() }.to(haveCount(2))
    }

    @Test("renameSavedQuery updates the name")
    func test_rename_saved_query() async throws {
        let created = try await service.createSavedQuery(named: "Old Name", using: BrowseFilters())
        let renamed = try await service.renameSavedQuery(withId: created.id, to: "New Name")
        expect(renamed.name).to(equal("New Name"))
    }

    @Test("deleteSavedQuery removes the record and returns true")
    func test_delete_saved_query() async throws {
        let created = try await service.createSavedQuery(named: "To Delete", using: BrowseFilters())
        let result = try await service.deleteSavedQuery(withId: created.id)
        expect(result).to(beTrue())
        await expect { try await self.service.savedQueryExists(withId: created.id) }.to(beFalse())
    }
}
```

- [ ] **Step 3: Run**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/GRDBSavesTest 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserTests/App/Services/Indexer/Service/GRDBSavesTest.swift
git commit -m "Add GRDBSaves unit tests."
```

---

### Task 14: GRDBQueues unit tests

**Files:**
- Modify: `HyperTagBrowser/App/Services/Indexer/Service/GRDBQueues.swift` (reference — do not modify)
- Create: `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBQueuesTest.swift`

**Interfaces:**
- Consumes: `TestSupportDB.setupDB()`, `GRDBIndexService` (ContentQueueAssociation), `IndexRecordFixture.Cases`

- [ ] **Step 1: Read the source file**

Read `HyperTagBrowser/App/Services/Indexer/Service/GRDBQueues.swift`. Public API:
- `createQueue(named:) throws -> QueueRecord`
- `insertIntoQueue(queueId:content:[ContentId]) throws`
- `insertIntoQueue(queueId:content:ContentId) throws`

Read `HyperTagBrowser/App/Services/Indexer/Records/` for the `QueueRecord` and `QueueItemRecord` types.

- [ ] **Step 2: Create `GRDBQueuesTest.swift`**

Create `HyperTagBrowserTests/App/Services/Indexer/Service/GRDBQueuesTest.swift` and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("GRDBQueues", .serialized, .tags(.indexer))
struct GRDBQueuesTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("createQueue persists a QueueRecord with the given name")
    func test_create_queue() async throws {
        let result = try await service.createQueue(named: "test-queue")
        expect(result.name).to(equal("test-queue"))
        expect(result.id).notTo(beEmpty())
    }

    @Test("insertIntoQueue adds items for a given ContentId")
    func test_insert_single_item() async throws {
        let q = try await service.createQueue(named: "single-insert-queue")
        let contentId = IndexRecordFixture.Cases.bakery.id
        try await service.insertIntoQueue(queueId: q.id, content: contentId)

        let items = try await queue.read { db in
            try QueueItemRecord.filter(Column("queueId") == q.id).fetchAll(db)
        }
        expect(items).to(haveCount(1))
        expect(items.first?.contentId).to(equal(contentId))
    }

    @Test("insertIntoQueue(queueId:content:[]) adds one item per ContentId")
    func test_insert_multiple_items() async throws {
        let q = try await service.createQueue(named: "multi-insert-queue")
        let ids = [IndexRecordFixture.Cases.bakery.id, IndexRecordFixture.Cases.bbq.id]
        try await service.insertIntoQueue(queueId: q.id, content: ids)

        let items = try await queue.read { db in
            try QueueItemRecord.filter(Column("queueId") == q.id).fetchAll(db)
        }
        expect(items).to(haveCount(2))
    }
}
```

- [ ] **Step 3: Run**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/GRDBQueuesTest 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserTests/App/Services/Indexer/Service/GRDBQueuesTest.swift
git commit -m "Add GRDBQueues unit tests."
```

---

## Phase 4 — Unit Tests: Tier 1 Request Types

> **Pattern for all request type tests:** Create a `DatabaseQueue` via `TestSupportDB.setupDB()`, then execute the request using GRDB's `ValueObservation` or a direct `fetchAll` call inside `queue.read`. Assert on the result.

### Task 15: ListIndexesRequest unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Requests/ListIndexesRequestTest.swift`

- [ ] **Step 1: Read the source**

Read `HyperTagBrowser/App/Services/Indexer/Records/Content/Query/ListIndexesRequest.swift`. Note the filtering parameters it accepts (visibility, type, tag matching, sort). Also read `IndxRequestParams` to understand how parameters are composed.

- [ ] **Step 2: Create `ListIndexesRequestTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("ListIndexesRequest", .serialized, .tags(.indexer, .indexRecord))
struct ListIndexesRequestTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("returns only visible records when visibility is .normal")
    func test_filters_by_visibility_normal() async throws {
        let params = IndxRequestParams(
            root: URL.temporaryDirectory.filepath,
            mode: .recursive(),
            visibility: .normal,
            options: [])

        await expect {
            try await self.service.getIndexes(matching: params)
        }
        .to(allPass { $0.visibility == .normal })
    }

    @Test("returns only hidden records when visibility is .hidden")
    func test_filters_by_visibility_hidden() async throws {
        let params = IndxRequestParams(
            root: URL.temporaryDirectory.filepath,
            mode: .recursive(),
            visibility: .hidden,
            options: [])

        let results = try await service.getIndexes(matching: params)
        expect(results).to(allPass { $0.visibility == .hidden })
    }

    @Test("returns all records when visibility is .any")
    func test_visibility_any_returns_all() async throws {
        let allIds = IndexRecordFixture.Cases.allCases.map(\.id)
        let params = IndxRequestParams(
            root: URL.temporaryDirectory.filepath,
            mode: .recursive(),
            visibility: .any,
            options: [])

        let results = try await service.getIndexes(matching: params)
        expect(results.map(\.contentId).asSet).to(equal(allIds.asSet))
    }

    @Test("filters by content type")
    func test_filters_by_type_video() async throws {
        let params = IndxRequestParams(
            root: URL.temporaryDirectory.filepath,
            mode: .recursive(),
            types: [.video],
            visibility: .any,
            options: [])

        let results = try await service.getIndexes(matching: params)
        expect(results).to(allPass { $0.conforms(to: .video) })
    }

    @Test("tag match with OR operator returns records matching any tag")
    func test_tag_match_or() async throws {
        let tags = TagRecordFixture.bbqGoods.asFilters.map(\.asInclusive)
        let params = IndxRequestParams(
            root: URL.temporaryDirectory.filepath,
            mode: .recursive(),
            tagsMatching: FilteringTagMultiParam(tags, operator: .or),
            visibility: .any,
            options: [])

        let results = try await service.getIndexes(matching: params)
        expect(results).notTo(beEmpty())
    }
}
```

- [ ] **Step 3: Run and fix**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/ListIndexesRequestTest 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserTests/App/Services/Indexer/Requests/ListIndexesRequestTest.swift
git commit -m "Add ListIndexesRequest unit tests."
```

---

### Task 16: CountIndexesRequest unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Requests/CountIndexesRequestTest.swift`

- [ ] **Step 1: Read the source**

Read `HyperTagBrowser/App/Services/Indexer/Records/Content/Query/CountIndexesRequest.swift`. It returns an integer count of matching records.

- [ ] **Step 2: Create `CountIndexesRequestTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("CountIndexesRequest", .serialized, .tags(.indexer, .indexRecord))
struct CountIndexesRequestTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("count with visibility .any equals total fixture record count")
    func test_count_all() async throws {
        let request = CountIndexesRequest(params: IndxRequestParams(
            root: URL.temporaryDirectory.filepath,
            mode: .recursive(),
            visibility: .any,
            options: []))

        let count = try queue.read { db in try request.fetchCount(db) }
        expect(count).to(equal(IndexRecordFixture.Cases.allCases.count))
    }

    @Test("count with visibility .normal excludes hidden records")
    func test_count_visible_only() async throws {
        let request = CountIndexesRequest(params: IndxRequestParams(
            root: URL.temporaryDirectory.filepath,
            mode: .recursive(),
            visibility: .normal,
            options: []))

        let total = try queue.read { db in try request.fetchCount(db) }
        expect(total).to(beLessThan(IndexRecordFixture.Cases.allCases.count))
    }
}
```

> Adjust `fetchCount` to match the actual API of `CountIndexesRequest` after reading the source.

- [ ] **Step 3: Run and fix**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/CountIndexesRequestTest 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add HyperTagBrowserTests/App/Services/Indexer/Requests/CountIndexesRequestTest.swift
git commit -m "Add CountIndexesRequest unit tests."
```

---

### Task 17: ListCountedTagsRequest unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Requests/ListCountedTagsRequestTest.swift`

- [ ] **Step 1: Read the source**

Read `HyperTagBrowser/App/Services/Indexer/Records/Tags/Query/ListCountedTagsRequest.swift`. Note the result type and any domain-filtering parameters.

- [ ] **Step 2: Create `ListCountedTagsRequestTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import GRDBQuery
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("ListCountedTagsRequest", .serialized, .tags(.indexer, .tagRecord))
struct ListCountedTagsRequestTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("returns non-empty list when tags are present")
    func test_returns_tags() async throws {
        let request = ListCountedTagsRequest()
        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results).notTo(beEmpty())
    }

    @Test("every result has a count greater than zero")
    func test_counts_are_positive() async throws {
        let request = ListCountedTagsRequest()
        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results).to(allPass { $0.count > 0 })
    }
}
```

> Adjust `ListCountedTagsRequest()` initializer and `fetchAll` to match the actual API.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/ListCountedTagsRequestTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Requests/ListCountedTagsRequestTest.swift
git commit -m "Add ListCountedTagsRequest unit tests."
```

---

### Task 18: ListIndexTagCountRequest unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Requests/ListIndexTagCountRequestTest.swift`

- [ ] **Step 1: Read** `Records/Tags/Query/ListIndexTagCountRequest.swift`. The request takes a list of `ContentId`s and returns per-file tag counts.

- [ ] **Step 2: Create `ListIndexTagCountRequestTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("ListIndexTagCountRequest", .serialized, .tags(.indexer, .tagRecord))
struct ListIndexTagCountRequestTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("returns tag count for each provided contentId")
    func test_returns_counts_for_ids() async throws {
        let ids = [IndexRecordFixture.Cases.bakery.id, IndexRecordFixture.Cases.bbq.id]
        var request = ListIndexTagCountRequest(contentIds: ids)

        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results.map(\.contentId).asSet).to(equal(ids.asSet))
    }

    @Test("returns empty list when given empty contentIds")
    func test_empty_ids_returns_empty() async throws {
        var request = ListIndexTagCountRequest(contentIds: [])
        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results).to(beEmpty())
    }
}
```

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/ListIndexTagCountRequestTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Requests/ListIndexTagCountRequestTest.swift
git commit -m "Add ListIndexTagCountRequest unit tests."
```

---

### Task 19: ListSavedQueriesRequest unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Requests/ListSavedQueriesRequestTest.swift`

- [ ] **Step 1: Read** `Records/SavedQueries/Query/ListSavedQueriesRequest.swift`.

- [ ] **Step 2: Create `ListSavedQueriesRequestTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("ListSavedQueriesRequest", .serialized, .tags(.indexer))
struct ListSavedQueriesRequestTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("returns empty list when no saved queries exist")
    func test_empty_when_none() async throws {
        let request = ListSavedQueriesRequest()
        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results).to(beEmpty())
    }

    @Test("returns all saved queries after insertion")
    func test_returns_all() async throws {
        try await queue.write { db in
            var q1 = SavedQueryRecord(name: "Alpha", query: BrowseFilters())
            var q2 = SavedQueryRecord(name: "Beta", query: BrowseFilters())
            try q1.insert(db)
            try q2.insert(db)
        }

        let request = ListSavedQueriesRequest()
        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results).to(haveCount(2))
    }
}
```

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/ListSavedQueriesRequestTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Requests/ListSavedQueriesRequestTest.swift
git commit -m "Add ListSavedQueriesRequest unit tests."
```

---

### Task 20: ListBookmarksRequest unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Requests/ListBookmarksRequestTest.swift`

- [ ] **Step 1: Read** `Records/Bookmarks/Query/ListBookmarksRequest.swift`.

- [ ] **Step 2: Create `ListBookmarksRequestTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import GRDB
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("ListBookmarksRequest", .serialized, .tags(.indexer))
struct ListBookmarksRequestTest {

    var service: GRDBIndexService
    var queue: DatabaseQueue

    init() async throws {
        (service, queue) = try await TestSupportDB.setupDB()
    }

    @Test("returns empty when no bookmarks exist")
    func test_empty() async throws {
        let request = ListBookmarksRequest()
        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results).to(beEmpty())
    }

    @Test("returns inserted bookmark in results")
    func test_returns_bookmark() async throws {
        let contentId = IndexRecordFixture.Cases.bakery.id
        let _ = try await service.createBookmark(to: contentId)

        let request = ListBookmarksRequest()
        let results = try queue.read { db in try request.fetchAll(db) }
        expect(results).to(haveCount(1))
        expect(results.first?.contentId).to(equal(contentId))
    }
}
```

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/ListBookmarksRequestTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Requests/ListBookmarksRequestTest.swift
git commit -m "Add ListBookmarksRequest unit tests."
```

---

## Phase 5 — Unit Tests: Tier 1 SQLite Functions

> **Pattern for all function tests:** call the static `fnExec` closure directly with typed inputs — no database required for pure functions. For `FilesDBFunctions` that read from disk, create a real temp file.

### Task 21: RegexpDatabaseFunctions unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Functions/RegexpDatabaseFunctionsTest.swift`

- [ ] **Step 1: Read** `Functions/RegexpDatabaseFunctions.swift`. The three functions are:
- `execRegexpMatch([string, pattern]) -> Bool?`
- `execRegexpCapture([string, pattern, Int]) -> String?`
- `execRegexpReplace([string, pattern, replacement]) -> String?`

- [ ] **Step 2: Create `RegexpDatabaseFunctionsTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("RegexpDatabaseFunctions", .tags(.indexer))
struct RegexpDatabaseFunctionsTest {

    // MARK: - regexpMatch

    @Test("regexpMatch returns true for matching input")
    func test_regexp_match_true() {
        let result = RegexpDBFunctions.execRegexpMatch(["hello world", "hello .*"])
        expect(result as? Bool).to(beTrue())
    }

    @Test("regexpMatch returns false for non-matching input")
    func test_regexp_match_false() {
        let result = RegexpDBFunctions.execRegexpMatch(["hello world", "^goodbye"])
        expect(result as? Bool).to(beFalse())
    }

    @Test("regexpMatch returns nil for nil input")
    func test_regexp_match_nil_input() {
        let result = RegexpDBFunctions.execRegexpMatch([Optional<String>.none as Any, ".*"])
        expect(result).to(beNil())
    }

    @Test("regexpMatch returns nil for invalid pattern")
    func test_regexp_match_invalid_pattern() {
        let result = RegexpDBFunctions.execRegexpMatch(["hello", "[invalid"])
        expect(result).to(beNil())
    }

    // MARK: - regexpCapture

    @Test("regexpCapture returns the first capture group")
    func test_regexp_capture_group_0() {
        let result = RegexpDBFunctions.execRegexpCapture(["[photography] sunset", #"\[(.*)\]"#, 0])
        expect(result as? String).to(equal("photography"))
    }

    @Test("regexpCapture returns nil when pattern does not match")
    func test_regexp_capture_no_match() {
        let result = RegexpDBFunctions.execRegexpCapture(["hello", #"\[(.*)\]"#, 0])
        expect(result).to(beNil())
    }

    // MARK: - regexpReplace

    @Test("regexpReplace returns replacement string when pattern matches")
    func test_regexp_replace_matches() {
        let result = RegexpDBFunctions.execRegexpReplace(["hello world", "world", "earth"])
        expect(result as? String).to(equal("earth"))
    }

    @Test("regexpReplace returns nil when pattern does not match")
    func test_regexp_replace_no_match() {
        let result = RegexpDBFunctions.execRegexpReplace(["hello", "^goodbye", "hi"])
        expect(result).to(beNil())
    }
}
```

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/RegexpDatabaseFunctionsTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Functions/RegexpDatabaseFunctionsTest.swift
git commit -m "Add RegexpDatabaseFunctions unit tests."
```

---

### Task 22: TextDatabaseFunctions unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Functions/TextDatabaseFunctionsTest.swift`

- [ ] **Step 1: Read** `Functions/TextDatabaseFunctions.swift`. Pure functions to test:
- `execTextConcat` — joins strings with no separator
- `execTextJoin` — first arg is separator, rest are joined
- `execHashId` — produces a deterministic hash string from inputs

- [ ] **Step 2: Create `TextDatabaseFunctionsTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("TextDatabaseFunctions", .tags(.indexer))
struct TextDatabaseFunctionsTest {

    @Test("textConcat joins all strings with no separator")
    func test_text_concat() {
        let result = TextDBFunctions.execTextConcat(["hello", " ", "world"])
        expect(result as? String).to(equal("hello world"))
    }

    @Test("textConcat returns empty string for empty input")
    func test_text_concat_empty() {
        let result = TextDBFunctions.execTextConcat([])
        expect(result as? String).to(equal(""))
    }

    @Test("textJoin uses first arg as separator")
    func test_text_join_with_separator() {
        let result = TextDBFunctions.execTextJoin(["-", "a", "b", "c"])
        expect(result as? String).to(equal("a-b-c"))
    }

    @Test("hashId returns a non-empty string for given inputs")
    func test_hash_id_non_empty() {
        let result = TextDBFunctions.execHashId(["alpha", "beta"])
        expect(result as? String).notTo(beEmpty())
    }

    @Test("hashId is deterministic for same inputs")
    func test_hash_id_deterministic() {
        let r1 = TextDBFunctions.execHashId(["same", "inputs"]) as? String
        let r2 = TextDBFunctions.execHashId(["same", "inputs"]) as? String
        expect(r1).to(equal(r2))
    }
}
```

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/TextDatabaseFunctionsTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Functions/TextDatabaseFunctionsTest.swift
git commit -m "Add TextDatabaseFunctions unit tests."
```

---

### Task 23: FileDatabaseFunctions unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Functions/FileDatabaseFunctionsTest.swift`

- [ ] **Step 1: Read** `Functions/FileDatabaseFunctions.swift`. Key pure functions:
- `execFileExists([URL]) -> Bool?` — checks filesystem
- `execConformsTo([UTType, UTType]) -> Bool?` — pure UTType check
- `execFileConformsTo([URL, UTType]) -> Bool?` — reads file content type
- `execFileContentType([URL]) -> String?` — reads content type from URL

- [ ] **Step 2: Create `FileDatabaseFunctionsTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble
import UniformTypeIdentifiers

@testable import HyperTagBrowser

@Suite("FileDatabaseFunctions", .tags(.indexer))
struct FileDatabaseFunctionsTest {

    var tempFile: URL!

    init() throws {
        let dir = FileManager.default.temporaryDirectory
        tempFile = dir.appendingPathComponent("testfile-\(UUID().uuidString).jpg")
        FileManager.default.createFile(atPath: tempFile.path, contents: Data([0xFF, 0xD8, 0xFF]))
    }

    // MARK: - fileExists

    @Test("fileExists returns true for an existing file")
    func test_file_exists_true() {
        let result = FilesDBFunctions.execFileExists([tempFile!])
        expect(result as? Bool).to(beTrue())
    }

    @Test("fileExists returns false for a non-existent path")
    func test_file_exists_false() {
        let missing = URL(fileURLWithPath: "/nonexistent/path/file.jpg")
        let result = FilesDBFunctions.execFileExists([missing])
        expect(result as? Bool).to(beFalse())
    }

    // MARK: - conformsTo

    @Test("conformsTo returns true when type hierarchy matches")
    func test_conforms_to_true() {
        let result = FilesDBFunctions.execConformsTo([UTType.jpeg, UTType.image])
        expect(result as? Bool).to(beTrue())
    }

    @Test("conformsTo returns false when types are unrelated")
    func test_conforms_to_false() {
        let result = FilesDBFunctions.execConformsTo([UTType.pdf, UTType.image])
        expect(result as? Bool).to(beFalse())
    }

    // MARK: - fileExistsIn

    @Test("fileExistsIn returns true when file exists in folder")
    func test_file_exists_in_true() {
        let folder = tempFile!.deletingLastPathComponent()
        let filename = tempFile!.lastPathComponent
        let result = FilesDBFunctions.execFileExistsIn([folder, filename])
        expect(result as? Bool).to(beTrue())
    }

    @Test("fileExistsIn returns false for unknown filename in folder")
    func test_file_exists_in_false() {
        let folder = tempFile!.deletingLastPathComponent()
        let result = FilesDBFunctions.execFileExistsIn([folder, "no-such-file.jpg"])
        expect(result as? Bool).to(beFalse())
    }
}
```

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/FileDatabaseFunctionsTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Functions/FileDatabaseFunctionsTest.swift
git commit -m "Add FileDatabaseFunctions unit tests."
```

---

## Phase 6 — Unit Tests: Tier 2 Pure Logic

> **Pattern for all Tier 2 tests:** no database required. Read the source file, construct instances with explicit values, and assert on the output.

### Task 24: SearchQuery + SearchQuery+Builder unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Search/SearchQueryTest.swift`

- [ ] **Step 1: Read** `Services/Search/SearchQuery.swift` and `SearchQuery+Builder.swift`. Understand how criteria are composed and what the query produces.

- [ ] **Step 2: Create `SearchQueryTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("SearchQuery", .tags(.dataModel))
struct SearchQueryTest {

    @Test("empty SearchQuery has no criteria")
    func test_empty_query() {
        let query = SearchQuery()
        expect(query.terms).to(beEmpty())
    }

    @Test("builder adds terms to the query")
    func test_builder_adds_terms() {
        let query = SearchQuery.Builder()
            .add(term: SearchTerm(text: "sunset"))
            .build()
        expect(query.terms).to(haveCount(1))
        expect(query.terms.first?.text).to(equal("sunset"))
    }

    @Test("builder with multiple terms produces a query with all of them")
    func test_builder_multiple_terms() {
        let query = SearchQuery.Builder()
            .add(term: SearchTerm(text: "alpha"))
            .add(term: SearchTerm(text: "beta"))
            .build()
        expect(query.terms).to(haveCount(2))
    }
}
```

> Adjust property names (`terms`, `text`, `Builder`) to match the actual API after reading the source.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/SearchQueryTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Search/SearchQueryTest.swift
git commit -m "Add SearchQuery unit tests."
```

---

### Task 25: SearchTerm + SearchTerm+Matcher unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Search/SearchTermTest.swift`

- [ ] **Step 1: Read** `Services/Search/SearchTerm.swift` and `SearchTerm+Matcher.swift`. Note how a term matches against a string.

- [ ] **Step 2: Create `SearchTermTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("SearchTerm", .tags(.dataModel))
struct SearchTermTest {

    @Test("term matches a string containing the search text")
    func test_matches_containing_text() {
        let term = SearchTerm(text: "sunset")
        expect(term.matches("Beautiful sunset photo")).to(beTrue())
    }

    @Test("term does not match unrelated string")
    func test_no_match_unrelated() {
        let term = SearchTerm(text: "sunset")
        expect(term.matches("Rainy afternoon")).to(beFalse())
    }

    @Test("matching is case-insensitive")
    func test_case_insensitive() {
        let term = SearchTerm(text: "SUNSET")
        expect(term.matches("sunset photo")).to(beTrue())
    }

    @Test("empty search text matches everything")
    func test_empty_text_matches_all() {
        let term = SearchTerm(text: "")
        expect(term.matches("anything")).to(beTrue())
    }
}
```

> Adjust `matches(_:)` to the actual method name after reading the source.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/SearchTermTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Search/SearchTermTest.swift
git commit -m "Add SearchTerm unit tests."
```

---

### Task 26: SearchQueryFragment unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Search/SearchQueryFragmentTest.swift`

- [ ] **Step 1: Read** `Services/Search/SearchQueryFragment.swift`. Note what SQL fragment it produces for given inputs.

- [ ] **Step 2: Create `SearchQueryFragmentTest.swift`** and add to **HyperTagBrowserTests**, writing tests for the specific fragment-building behavior documented in the source.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/SearchQueryFragmentTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Search/SearchQueryFragmentTest.swift
git commit -m "Add SearchQueryFragment unit tests."
```

---

### Task 27: FilePredicates unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/LocalFiles/FilePredicatesTest.swift`

- [ ] **Step 1: Read** `Services/LocalFiles/Data/FilePredicates.swift`. Note each predicate function and its expected inputs/outputs.

- [ ] **Step 2: Create `FilePredicatesTest.swift`** and add to **HyperTagBrowserTests**, writing one `@Test` per predicate covering match and no-match cases.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/FilePredicatesTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/LocalFiles/FilePredicatesTest.swift
git commit -m "Add FilePredicates unit tests."
```

---

### Task 28: FilenameData unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/LocalFiles/FilenameDataTest.swift`

- [ ] **Step 1: Read** `Services/LocalFiles/Data/FilenameData.swift`. Focus on extension extraction, base name parsing, and hidden file detection.

- [ ] **Step 2: Create `FilenameDataTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("FilenameData", .tags(.dataModel))
struct FilenameDataTest {

    @Test("extension is extracted from filename")
    func test_extension_from_filename() {
        let data = FilenameData(filename: "photo.jpg")
        expect(data.fileExtension).to(equal("jpg"))
    }

    @Test("base name excludes extension")
    func test_base_name() {
        let data = FilenameData(filename: "photo.jpg")
        expect(data.baseName).to(equal("photo"))
    }

    @Test("hidden file detected by leading dot")
    func test_hidden_file() {
        let data = FilenameData(filename: ".hidden")
        expect(data.isHidden).to(beTrue())
    }

    @Test("non-hidden file not detected as hidden")
    func test_not_hidden() {
        let data = FilenameData(filename: "visible.txt")
        expect(data.isHidden).to(beFalse())
    }
}
```

> Adjust property names to match the actual API after reading the source.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/FilenameDataTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/LocalFiles/FilenameDataTest.swift
git commit -m "Add FilenameData unit tests."
```

---

### Task 29: ContentTypeGrouping unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/LocalFiles/ContentTypeGroupingTest.swift`

- [ ] **Step 1: Read** `Services/LocalFiles/Data/ContentTypeGrouping.swift`. Note the UTType → group mapping and the fallback for unknown types.

- [ ] **Step 2: Create `ContentTypeGroupingTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble
import UniformTypeIdentifiers

@testable import HyperTagBrowser

@Suite("ContentTypeGrouping", .tags(.dataModel))
struct ContentTypeGroupingTest {

    @Test("JPEG is classified as image group")
    func test_jpeg_is_image() {
        let group = ContentTypeGrouping.group(for: UTType.jpeg)
        expect(group).to(equal(.images))
    }

    @Test("PDF is classified as document group")
    func test_pdf_is_document() {
        let group = ContentTypeGrouping.group(for: UTType.pdf)
        expect(group).to(equal(.documents))
    }

    @Test("folder is classified as folder group")
    func test_folder_is_folder() {
        let group = ContentTypeGrouping.group(for: UTType.folder)
        expect(group).to(equal(.folders))
    }

    @Test("unknown type falls back to a default group")
    func test_unknown_type_fallback() {
        let group = ContentTypeGrouping.group(for: UTType.data)
        expect(group).notTo(beNil())
    }
}
```

> Adjust `ContentTypeGrouping.group(for:)` and group enum cases to match the actual API.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/ContentTypeGroupingTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/LocalFiles/ContentTypeGroupingTest.swift
git commit -m "Add ContentTypeGrouping unit tests."
```

---

### Task 30: FilteringTagMultiParam unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Parameters/FilteringTagMultiParamTest.swift`

- [ ] **Step 1: Read** `Services/Indexer/Parameters/FilteringTagMultiParam.swift`. Note how AND/OR operators affect the SQL fragment produced.

- [ ] **Step 2: Create `FilteringTagMultiParamTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("FilteringTagMultiParam", .tags(.dataModel))
struct FilteringTagMultiParamTest {

    @Test("OR operator produces a param with the given tags")
    func test_or_operator() {
        let tags = [FilteringTag.tag("red").asInclusive, FilteringTag.tag("blue").asInclusive]
        let param = FilteringTagMultiParam(tags, operator: .or)
        expect(param.tags).to(haveCount(2))
        expect(param.operator).to(equal(.or))
    }

    @Test("AND operator produces a param with the given tags")
    func test_and_operator() {
        let tags = [FilteringTag.tag("x").asInclusive, FilteringTag.tag("y").asInclusive]
        let param = FilteringTagMultiParam(tags, operator: .and)
        expect(param.operator).to(equal(.and))
    }

    @Test("empty tag list produces a param with no tags")
    func test_empty_tags() {
        let param = FilteringTagMultiParam([], operator: .or)
        expect(param.tags).to(beEmpty())
    }

    @Test("single tag is preserved")
    func test_single_tag() {
        let param = FilteringTagMultiParam([FilteringTag.tag("solo").asInclusive], operator: .or)
        expect(param.tags).to(haveCount(1))
    }
}
```

> Adjust property names (`tags`, `operator`) to match the actual API.

- [ ] **Step 3: Run and fix**, then commit:

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/FilteringTagMultiParamTest 2>&1 | tail -20
git add HyperTagBrowserTests/App/Services/Indexer/Parameters/FilteringTagMultiParamTest.swift
git commit -m "Add FilteringTagMultiParam unit tests."
```

---

### Task 31: TagQueryParameters unit tests

**Files:**
- Create: `HyperTagBrowserTests/App/Services/Indexer/Parameters/TagQueryParametersTest.swift`

- [ ] **Step 1: Read** `Services/Indexer/Parameters/TagQueryParameters.swift`. Note how it builds parameters from `FilteringTag` arrays.

- [ ] **Step 2: Create `TagQueryParametersTest.swift`** and add to **HyperTagBrowserTests**.

```swift
import Foundation
import Testing
import Nimble

@testable import HyperTagBrowser

@Suite("TagQueryParameters", .tags(.dataModel))
struct TagQueryParametersTest {

    @Test("builds parameters from a non-empty FilteringTag array")
    func test_build_from_tags() {
        let tags: [FilteringTag] = [.tag("alpha"), .tag("beta")]
        let params = TagQueryParameters(tags: tags)
        expect(params.tags).to(haveCount(2))
    }

    @Test("empty tag array produces empty parameters")
    func test_empty_tags() {
        let params = TagQueryParameters(tags: [])
        expect(params.tags).to(beEmpty())
    }
}
```

> Adjust initializer and property names to match the actual API.

- [ ] **Step 3: Run and fix**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests/TagQueryParametersTest 2>&1 | tail -20
```

- [ ] **Step 4: Run the complete unit test suite**

```bash
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' \
    -only-testing:HyperTagBrowserTests 2>&1 | tail -30
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add HyperTagBrowserTests/App/Services/Indexer/Parameters/TagQueryParametersTest.swift
git commit -m "Add TagQueryParameters unit tests. All Tier 2 pure-logic tests complete."
```
