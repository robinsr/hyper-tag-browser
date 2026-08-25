# Testing Strategy Design

**Date:** 2026-08-25  
**Status:** Draft

## Context

HyperTagBrowser is a solo hobby macOS SwiftUI app. The primary pain point is regressions at the data/query logic layer — GRDB service methods and request types break silently because they have no tests. The existing test infrastructure (Quick, Nimble, XCTest, `DatabaseTestFixture`, record fixtures) is solid but coverage is thin. The goal is to close that gap systematically using AI-generated unit tests, plus add a thin XCUITest smoke layer to catch catastrophic UI regressions.

## Strategy: Option B

**Bulk unit tests** targeting the data/query layer, generated with AI file-by-file.  
**XCUITest smoke layer** of 5 hand-written scenarios covering critical happy paths.

## Unit Test Scope

### Tier 1 — GRDB service methods (highest priority)

These follow the same pattern as existing `GRDBTagsTest`/`GRDBIndexesTest`/`GRDBTagAssociationsTest` and use `DatabaseTestFixture` + record fixtures directly.

| File | Notes |
|------|-------|
| `Service/GRDBBookmarks.swift` | Bookmark CRUD |
| `Service/GRDBSaves.swift` | Saved query CRUD |
| `Service/GRDBQueues.swift` | Work queue management |

### Tier 1 — Request types with non-trivial query logic

| File | Notes |
|------|-------|
| `Records/Content/Query/ListIndexesRequest.swift` | Filtering, sorting |
| `Records/Content/Query/CountIndexesRequest.swift` | Aggregate query |
| `Records/Tags/Query/ListCountedTagsRequest.swift` | Tag counts |
| `Records/Tags/Query/ListIndexTagCountRequest.swift` | Per-index tag counts |
| `Records/SavedQueries/Query/ListSavedQueriesRequest.swift` | Saved query listing |
| `Records/Bookmarks/Query/ListBookmarksRequest.swift` | Bookmark listing |

### Tier 1 — Custom SQLite functions

Pure functions registered on the database connection. Test each function directly with known inputs and expected outputs.

| File | Notes |
|------|-------|
| `Functions/RegexpDatabaseFunctions.swift` | Regex matching in SQL |
| `Functions/TextDatabaseFunctions.swift` | Text search helpers |
| `Functions/FileDatabaseFunctions.swift` | File path operations |

### Tier 2 — Pure logic (no database required)

| File | Notes |
|------|-------|
| `Services/Search/SearchQuery.swift` + `SearchQuery+Builder.swift` | Query composition |
| `Services/Search/SearchTerm.swift` + `SearchTerm+Matcher.swift` | Term matching logic |
| `Services/Search/SearchQueryFragment.swift` | Fragment building |
| `Services/LocalFiles/Data/FilePredicates.swift` | File filtering predicates |
| `Services/LocalFiles/Data/FilenameData.swift` | Filename parsing |
| `Services/LocalFiles/Data/ContentTypeGrouping.swift` | UTType grouping logic |
| `Services/Indexer/Parameters/FilteringTagMultiParam.swift` | Parameter building |
| `Services/Indexer/Parameters/TagQueryParameters.swift` | Parameter building |

### Tier 3 — Skip for now

- `Service/GRDBIndexer.swift` — actual file walker; covered by e2e
- `Services/System/*` — require real OS integration (Clipboard, QuickLook, Volumes)
- `Services/Search/SpotlightService.swift` — requires Spotlight daemon
- `Services/ML/*` — external helper client

## AI Generation Workflow

For each Tier 1/2 file:

1. Point Claude at the target service file
2. Claude reads: the target file, relevant record/fixture files, and an existing test file for style reference
3. Claude generates a full Quick/Nimble test file matching existing patterns:
   - `describe`/`context`/`it` structure
   - Real in-memory SQLite via `DatabaseTestFixture`
   - `AssertEqualDiff` for complex struct comparisons
   - `expect(...).to(...)` Nimble matchers
4. Run tests; fix failures before moving to next file

**Order:** Tier 1 GRDB services → Tier 1 request types → Tier 1 SQLite functions → Tier 2 pure logic

No new test infrastructure is required. All scaffolding needed for Tier 1 already exists.

## XCUITest Smoke Scenarios

Five hand-written scenarios (not AI-generated). XCUITest is too coupled to live UI state for reliable generation.

| # | Scenario | Pass condition |
|---|----------|---------------|
| 1 | App launches | Browse screen visible, sidebar present, no crash |
| 2 | Folder loads | Launch with `LaunchFolderPath` arg; file grid is non-empty |
| 3 | Tag applied to file | Select a file, apply a tag; tag appears in file's tag list |
| 4 | Saved query runs | Open a saved query; results list is non-empty |
| 5 | Bookmark created | Bookmark a folder; it appears in the bookmarks list |

### Accessibility identifier contract

Before writing scenario bodies, add `.accessibilityIdentifier(...)` to these elements in the SwiftUI views. The XCUITest files reference these identifiers — views follow tests, not the other way around.

Identifiers needed (approximate — confirm against actual view files):

- `browse-screen` — root browse view
- `sidebar` — sidebar container
- `file-grid` — file grid/collection view
- `file-grid-item` — individual file cell
- `tag-input` — tag entry field
- `tag-list` — tag list on selected file
- `saved-query-list` — saved queries sidebar section
- `saved-query-item` — individual saved query row
- `bookmark-list` — bookmarks sidebar section
- `bookmark-item` — individual bookmark row

### Test file location

`HyperTagBrowserUITests/Screens/` — the existing `BrowseScreenUITest.swift` is a placeholder; the smoke scenarios replace its placeholder content.

## What This Does Not Cover

- ViewModel state (`@Observable` ViewModels) — the pain is in the data layer, not VMs; revisit if that changes
- Migration correctness — migrations already run against the real schema on every test run via `DatabaseTestFixture`
- ML/Spotlight integration — external dependencies, not worth the isolation cost
