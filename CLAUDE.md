# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About the App

HyperTagBrowser is a native macOS file browser (macOS 15.0+) built with SwiftUI. It indexes local directories into a SQLite database and provides advanced tagging, filtering, and file organization. The app bundle ID is `com.robinsr.taggedfilebrowser`.

## Build & Test Commands

```bash
# Build
xcodebuild build -scheme HyperTagBrowser -destination 'platform=macOS'

# Run all tests
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS'

# Run unit tests only
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests

# Run a single test class
xcodebuild test -scheme HyperTagBrowser -destination 'platform=macOS' -only-testing:HyperTagBrowserTests/GRDBTagsTest
```

Test plans: `UnitTests.xctestplan` (unit only), `HyperTagBrowser-Debug.xctestplan` (full debug run).

## Code Formatting

`.swift-format` is at `HyperTagBrowser/.swift-format`: 100-character line length, 2-space indent, file-scoped private declarations, no semicolons, no force-unwraps. Run `swift-format` before committing.

## Architecture

**Pattern:** MVVM with unidirectional action dispatch. The `ActionDispatcher` in `App/Data/Runtime/` handles cross-cutting state changes via a reducer-style `Actions` enum. Views observe `@Observable` or `@ObservableObject` ViewModels and dispatch named actions rather than mutating state directly.

**Dependency Injection:** Factory (`App/Data/Runtime/Container.swift` and `App/Services/Indexer/IndexerContainer.swift`). All services are registered as Factory containers. Tests use `FactoryTesting` to swap registrations.

**Database layer:** GRDB (`App/Services/Indexer/`). Record types live in `Records/`, schema migrations in `Migrations/`, and reactive queries use `GRDBQuery`. Custom SQLite functions (regex, file ops, text search) are registered in `Functions/`. The database schema is configured in `SchemaConfiguration.swift`.

**Key service areas:**
- `Services/Indexer/` — file indexing, tagging records, saved queries, work queues
- `Services/LocalFiles/` — file system reads, `FileTree`, `FileCache`, extended attributes via XAttr
- `Services/Search/` — Spotlight integration, `SearchQuery` composable criteria
- `Services/System/` — clipboard, QuickLook, metadata extraction, theme management

**Preferences:** Multi-profile system in `App/Data/Preferences/`. `Defaults` (library) backs individual preference keys. Profiles: `ActiveUserProfile`, `DefaultUserProfile`, `ExternalUserProfile`. Per-folder settings live in `UserFolderPrefs`. Dev/debug flags are in `DevFlags`.

**Testing infrastructure:** `HyperTagBrowserTests/TestSupport/` has shared utilities and `AssertEqualDiff`. Test fixtures for the database are in `Services/Indexer/Fixtures/`. Tests use Quick (BDD) + Nimble matchers alongside XCTest.

## Versioning

`versioning.xcconfig` holds `BUILD_NUMBER` and `VERSION`. `versioning.sh` auto-updates these from git tags and a timestamp (`YYYYMMDDHHmmss`). The script is invoked as a build phase — don't manually edit `versioning.xcconfig` during development.

## Entitlements & Permissions

Full Disk Access is required for file indexing (`TaggedFileBrowser.entitlements`). The app registers a custom URL scheme (`tfb://`) and custom UTTypes for `FilteringTag`, `ContentPointer`, and SQLite database files (see `Info.plist`).
