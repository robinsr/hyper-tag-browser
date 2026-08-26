# Test Improvements Design

**Date:** 2026-08-25  
**Status:** Approved  
**Supersedes:** `docs/specs/2026-08-25-testing-strategy-design.md`

---

## Context and Goals

HyperTagBrowser is a macOS file manager app. Its behavior is deeply coupled to filesystem state (what files exist on disk), SQLite database state (indexed records, tags, bookmarks, saved queries), and GRDB reactive queries. Regressions in these integration points break the entire app.

**Primary goal:** Reliable, repeatable XCUITest coverage of the file-system-integrated behavior — the category of breakage that takes everything down with it.

**Secondary goal:** Unit test coverage for GRDB query logic, custom SQLite functions, and pure business logic that currently fails silently.

**Non-goals (explicitly out of scope):**
- Spotlight integration
- System xattr side-effects from external processes
- ML helper client
- GraphQL server (`/server` folder)
- `Services/System/*` (Clipboard, QuickLook, Volumes — require real OS integration)

---

## Framework Decisions

| Layer | Framework | Rationale |
|---|---|---|
| Unit tests | Swift Testing + Nimble | What the codebase already uses; Apple's current standard as of Swift 5.9/Xcode 16 |
| XCUITests | XCTest + Nimble | Plain XCTest; BDD vocabulary adds noise at the scenario layer |
| CI (future) | Xcode Cloud | Fresh macOS VM per build; complements local hermetic setup |

**Quick is removed entirely.** The existing `HyperTagBrowserUITests/Screens/Browse/BrowseScreenUITest.swift` (Quick-based placeholder) is deleted and replaced with an XCTest implementation.

---

## Work Order

```
Step 0  (prerequisite)
  └─ Re-enable existing tests; run suite; fix all failures

Step 1  Build UITestEnvironment infrastructure
Step 2  Add accessibility identifiers to views; write 5 XCUITest scenarios
Step 3A Tier 1 unit tests: GRDB service methods (3 files)
Step 3B Tier 1 unit tests: Request types (6 files)
Step 3C Tier 1 unit tests: Custom SQLite functions (3 files)
Step 3D Tier 2 unit tests: Pure logic (8 files)
```

Steps 3A–3D are sequential within themselves. Steps 1–2 (XCUITest track) and Steps 3A–3D (unit test track) are independent once Step 0 passes and can proceed in parallel.

---

## Step 0: Re-Enable Existing Tests

All existing unit tests carry `.disabled("Disabled for project migration")`. The migration (TaggedFileBrowser → HyperTagBrowser) is complete; these tests are intended to work again.

**Action:** Remove the `.disabled(...)` attribute from every `@Test` declaration. Run the full suite. Fix any failures before proceeding. This is a hard gate — no new tests are generated until the existing suite is green.

Likely failure modes: method or type renames from the migration. The module name `HyperTagBrowser` in `@testable import HyperTagBrowser` is already correct.

---

## Hermetic Test Environment Architecture

### The Problem

XCUITests run the real app as a separate process. The app's behavior depends on what files exist on disk and what is in its SQLite database. To make tests repeatable without requiring the developer's Mac to be in a specific state, both must be controlled.

### Component 1 — Fixture File Set

A small folder of real files committed into the UITest target as bundle resources:

```
HyperTagBrowserUITests/TestFixtures/Files/
```

Sourced from `/Users/ryan/workspace/projects/taggedfilebrowser/testimages` — approximately 10–15 files of mixed types (images, a PDF, a plain document). Mixed types are required because the app branches on `UTType` in several places.

Before each test, `UITestEnvironment.setUp()` copies these files from the bundle into a fresh `$TMPDIR` subdirectory. `tearDown()` removes it. Tests never touch real user files.

### Component 2 — App UITest Launch Mode (DEBUG only)

A `#if DEBUG` block in the app responds to launch arguments:

- `--UITestMode` — switches the active database path from the user's real Application Support database to a path inside the temp folder; disables launch animations; seeds the temp database with fixture records using the same `IndexRecordFixture` / `TagRecordFixture` / `IndexTagRecordFixture` types already defined in the codebase. Fixture record file paths are rewritten to point into the temp folder so `file.exists` checks return `true`.
- `--UITestMode --LiveIndex` — same temp folder, but skips pre-seeding. Used for the live-indexing smoke scenario. The app indexes the fixture files from scratch.
- `--LoadSavedQuery=<id>` — (optional, used in Scenario 4) applies a named saved query on launch.

No binary `.sqlite` file is committed to the repo. The database is regenerated fresh each test run from Swift fixture definitions, keeping it in sync automatically when fixtures or schema change.

### Component 3 — `UITestEnvironment` Helper

A struct in `HyperTagBrowserUITests/` that owns setup and teardown:

```swift
struct UITestEnvironment {
    let tempDir: URL
    let app: XCUIApplication

    static func setUp(liveIndex: Bool = false, loadSavedQuery: String? = nil) throws -> UITestEnvironment
    func tearDown()
}
```

`setUp()` creates the temp dir, copies fixture files, configures `app.launchArguments`, and calls `app.launch()`. Every `XCTestCase` subclass calls this in `setUpWithError()` / `tearDownWithError()`. No test touches `XCUIApplication` directly — all access goes through `UITestEnvironment`.

### Component 4 — Screen Objects

Lightweight structs (not a full Page Object Model) that wrap `XCUIElement` queries behind readable properties. They hold no state — just a reference to `XCUIApplication` and named element accessors:

```swift
struct BrowseScreen {
    let app: XCUIApplication
    var fileGrid: XCUIElement   { app.grids["photo-grid"] }
    var sidebar: XCUIElement    { app.scrollViews["browse-sidebar"] }
    var bookmarksList: XCUIElement { app.otherElements["bookmarks-list"] }
}

struct DetailScreen {
    let app: XCUIApplication
    var tagSearchField: XCUIElement  { app.searchFields["tag-search-field"] }
    var appliedTagsView: XCUIElement { app.otherElements["applied-tags-view"] }
}
```

---

## XCUITest Smoke Scenarios

### Test Structure

```swift
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

Each scenario is a `final class` extending `BaseUITest`. Scenarios that need non-default `UITestEnvironment` options (e.g., Scenario 2's `liveIndex: true`) override `setUpWithError()` rather than relying on the base class.

### Scenario Split

| # | Scenario | Mode | What it exercises |
|---|---|---|---|
| 1 | App launches cleanly | `--UITestMode` | Pre-seeded DB, UI visible, no crash |
| 2 | Folder loads via live indexing | `--UITestMode --LiveIndex` | Full indexer → GRDB → UI pipeline |
| 3 | Tag applied to a file | `--UITestMode` | Pre-seeded DB, tag write path, reactive UI update |
| 4 | Saved query loads | `--UITestMode --LoadSavedQuery=<id>` | Pre-seeded DB, query read path, file grid populates |
| 5 | Bookmark created | `--UITestMode` | Pre-seeded DB, bookmark write path, sidebar updates |

### Scenario Bodies

**Scenario 1 — App launches cleanly**
```swift
func test_app_launches() {
    let screen = BrowseScreen(app: env.app)
    expect(screen.fileGrid.exists).to(beTrue())
    expect(screen.sidebar.exists).to(beTrue())
}
```

**Scenario 2 — Folder loads via live indexing**
```swift
func test_folder_loads_live() {
    let screen = BrowseScreen(app: env.app)
    expect(screen.fileGrid.cells.count).to(beGreaterThan(0))
}
```
`UITestEnvironment.setUp(liveIndex: true)` — the app indexes the fixture temp dir from scratch. `XCUIApplication.launch()` waits for idle before returning.

**Scenario 3 — Tag applied to a file**
```swift
func test_tag_applied_to_file() {
    let browse = BrowseScreen(app: env.app)
    browse.fileGrid.cells.firstMatch.tap()

    let detail = DetailScreen(app: env.app)
    detail.tagSearchField.typeText("smoke-tag\n")

    expect(detail.appliedTagsView.buttons["smoke-tag"].exists).to(beTrue())
}
```
"smoke-tag" does not need to pre-exist in the fixture DB — `AddTagView` creates new tags on submit.

**Scenario 4 — Saved query loads**
```swift
func test_saved_query_loads() {
    // env is set up with --LoadSavedQuery=UITestFixtures.savedQueryId (a deterministic constant)
    let screen = BrowseScreen(app: env.app)
    expect(screen.fileGrid.cells.count).to(beGreaterThan(0))
}
```
The fixture DB includes one `SavedQueryRecord` with a hardcoded deterministic ID (e.g., `UITestFixtures.savedQueryId = "fixture-saved-query-1"`). The fixture query's criteria are crafted to match at least some of the seeded `IndexRecord` entries.

**Scenario 5 — Bookmark created**
```swift
func test_bookmark_created() {
    let browse = BrowseScreen(app: env.app)
    browse.fileGrid.cells.firstMatch.rightClick()
    env.app.menuItems["Add Bookmark"].tap()

    expect(browse.bookmarksList.cells.count).to(beGreaterThan(0))
}
```
Fixture data includes at least one folder-type `IndexRecord` so the context menu bookmark action is always available.

### Accessibility Identifier Contract

Add `.accessibilityIdentifier(...)` to these elements before writing scenario bodies. Views follow tests — only what the scenarios above require:

| View file | Element | Identifier |
|---|---|---|
| `PhotoGridView.swift` | `LazyVGrid` | `"photo-grid"` |
| `BrowseScreen.swift` | sidebar `ScrollView` | `"browse-sidebar"` |
| `AddTagView.swift` | `SearchField` | `"tag-search-field"` |
| `ImageInspector.swift` | `CurrentTagsView` container | `"applied-tags-view"` |
| `Bookmarks_List.swift` | `ListItems` VStack | `"bookmarks-list"` |

---

## Unit Test Scope

### Test Pattern

All new unit tests use Swift Testing + Nimble, matching the existing codebase:

```swift
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

    @Test("createBookmark - persists a BookmarkRecord")
    func test_create_bookmark() async throws {
        // ...
        expect(result).notTo(beNil())
    }
}
```

`TestSupportDB.setupDB()` provides the in-memory GRDB database with fixture data for all Tier 1 tests. Tier 2 pure-logic tests need no database.

### Generation Workflow

For each file, in order:

1. Provide the target source file, relevant record/fixture files, and one existing passing test file for style reference
2. Generate a full Swift Testing test file matching existing patterns
3. Run the suite; fix failures before proceeding to the next file

No batch generation. Each file is completed and verified before the next begins.

### Tier 1 — GRDB Service Methods

Use `TestSupportDB.setupDB()`. Cover the happy path, not-found cases, and any non-trivial logic branches in each service.

| File | Test focus |
|---|---|
| `Service/GRDBBookmarks.swift` | Create, fetch, delete bookmark records; fetch by folder path |
| `Service/GRDBSaves.swift` | Create, fetch, update, delete saved query records |
| `Service/GRDBQueues.swift` | Enqueue, dequeue, clear work queue items; state transitions |

### Tier 1 — Request Types

Use a real in-memory DB seeded with fixtures. Test each filtering and sorting dimension the request type supports.

| File | Test focus |
|---|---|
| `Records/Content/Query/ListIndexesRequest.swift` | Type filter, visibility filter, tag match (AND/OR), sort orders |
| `Records/Content/Query/CountIndexesRequest.swift` | Count matches standard filtering permutations |
| `Records/Tags/Query/ListCountedTagsRequest.swift` | Tag counts per domain; zero-count exclusion |
| `Records/Tags/Query/ListIndexTagCountRequest.swift` | Per-file tag counts for a given set of content IDs |
| `Records/SavedQueries/Query/ListSavedQueriesRequest.swift` | List all; filter by name |
| `Records/Bookmarks/Query/ListBookmarksRequest.swift` | List all; ordering |

### Tier 1 — Custom SQLite Functions

Functions are registered on the database connection and called via SQL. Tests construct minimal SQL queries that invoke each function with known inputs and assert on the output.

| File | Test focus |
|---|---|
| `Functions/RegexpDatabaseFunctions.swift` | Match / no-match; empty pattern; nil input edge cases |
| `Functions/TextDatabaseFunctions.swift` | Text normalization; search term matching |
| `Functions/FileDatabaseFunctions.swift` | Path extraction; extension matching; base name operations |

### Tier 2 — Pure Logic

No database required. Plain Swift Testing suites.

| File | Test focus |
|---|---|
| `Search/SearchQuery.swift` + `SearchQuery+Builder.swift` | Builder produces correct query structures; chained criteria compose correctly |
| `Search/SearchTerm.swift` + `SearchTerm+Matcher.swift` | Term matching against known strings; case sensitivity; partial match |
| `Search/SearchQueryFragment.swift` | Fragment SQL output for given inputs |
| `LocalFiles/Data/FilePredicates.swift` | Predicate evaluation against known values |
| `LocalFiles/Data/FilenameData.swift` | Extension extraction; base name parsing; hidden file detection |
| `LocalFiles/Data/ContentTypeGrouping.swift` | UTType → group mapping; unknown type fallback |
| `Indexer/Parameters/FilteringTagMultiParam.swift` | AND / OR operator output; empty input; single-item input |
| `Indexer/Parameters/TagQueryParameters.swift` | Parameter building from `FilteringTag` arrays |

### Tier 3 — Skip

| File | Reason |
|---|---|
| `Service/GRDBIndexer.swift` | Actual file walker; covered by Scenario 2 (live-index e2e) |
| `Services/System/*` | Require real OS integration (Clipboard, QuickLook, Volumes) |
| `Services/Search/SpotlightService.swift` | Requires Spotlight daemon |
| `Services/ML/*` | External helper client |
